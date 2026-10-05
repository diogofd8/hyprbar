pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Qt.labs.folderlistmodel

import qs

Singleton {
    id: root

    // ────── Public API ──────
    readonly property bool available: deviceName !== "" && maxRaw > 0

    readonly property int value:
        available ? Math.round(targetRaw / maxRaw * 100) : 0

    readonly property int levelIndex:
        resolveLevelIndex(value, Settings.brightnessLevelThresholds)

    readonly property string level:
        Settings.brightnessLevelThresholds[levelIndex].state

    readonly property string icon:
        Settings.brightnessCtrlIcon[
            Math.min(levelIndex, Settings.brightnessCtrlIcon.length - 1)]

    // The bar uses the internal panel continuously. Popup discovery and its
    // periodic reads run only while the brightness manager is open.
    property bool discoveryActive: false
    readonly property var screenEntryModel: screenEntries
    readonly property var keyboardEntryModel: keyboardEntries

    property bool nightLightLoaded: false
    property bool nightLightEnabled: false
    property int nightTemperature: 0
    property string nightLightError: ""
    readonly property bool nightLightBusy: nightQueryPending || nightSetter.running

    property int keyboardLevel: -1
    property int keyboardMax: -1
    property string keyboardError: ""
    readonly property bool keyboardAvailable: keyboardMax === 2 && keyboardLevel >= 0
    readonly property bool keyboardBusy: keyboardSetter.running

    property string screenError: ""
    property bool ddcBusy: false

    ListModel {
        id: screenEntries
        ListElement {
            kind: "internal"
            bus: -1
            name: "Internal Display"
            connector: ""
            value: 0
            max: 100
            available: false
            busy: false
        }
    }

    ListModel {
        id: keyboardEntries
        ListElement {
            kind: "keyboard"
            bus: -1
            name: "ThinkPad Keyboard"
            connector: ""
            value: 0
            max: 2
            available: false
            busy: false
        }
    }

    function updateInternalEntry() {
        if (screenEntries.count === 0)
            return
        screenEntries.setProperty(0, "value", value)
        screenEntries.setProperty(0, "available", available)
    }

    function updateKeyboardEntry() {
        if (keyboardEntries.count === 0)
            return
        keyboardEntries.setProperty(0, "value", Math.max(0, keyboardLevel))
        keyboardEntries.setProperty(0, "max", Math.max(1, keyboardMax))
        keyboardEntries.setProperty(0, "available", keyboardAvailable)
        keyboardEntries.setProperty(0, "busy", keyboardBusy)
    }

    onValueChanged: updateInternalEntry()
    onAvailableChanged: updateInternalEntry()
    onKeyboardLevelChanged: updateKeyboardEntry()
    onKeyboardMaxChanged: updateKeyboardEntry()
    onKeyboardAvailableChanged: updateKeyboardEntry()
    onKeyboardBusyChanged: updateKeyboardEntry()

    Component.onCompleted: {
        updateInternalEntry()
        updateKeyboardEntry()
    }

    // ────── Actions ──────
    function setBrightness(percent) {
        if (!available)
            return

        applyRaw(Math.round(percent / 100 * maxRaw))
    }

    // `steps` is a count, matching ChevronButton's scrolled(steps).
    function stepBrightness(steps) {
        if (!available)
            return

        // Stepping from targetRaw rather than from the hardware reading: a
        // fast scroll fires several steps before sysfs has caught up, and
        // computing each one from the stale reading would collapse them all
        // into a single step.
        const stepRaw = Math.max(
            1, Math.round(maxRaw * Settings.brightnessStepPercentage / 100))

        applyRaw(targetRaw + steps * stepRaw)
    }

    function setEntryBrightness(kind, bus, amount) {
        switch (kind) {
        case "internal": setBrightness(amount); break
        case "external": setExternalBrightness(bus, amount); break
        case "keyboard": setKeyboardLevel(amount); break
        }
    }

    // ────── Internals ──────
    property string deviceName: ""
    property int maxRaw: 0
    property int rawValue: 0
    property int targetRaw: 0

    function applyRaw(raw) {
        const floor = Math.ceil(maxRaw * Settings.brightnessMinPercentage / 100)

        root.targetRaw = Math.max(floor, Math.min(maxRaw, Math.round(raw)))

        setter.running = false
        setter.command = [
            "brightnessctl", "--device", root.deviceName,
            "set", String(root.targetRaw)
        ]
        setter.running = true
    }

    // Anything that moves the backlight from outside — the function keys, or
    // another tool — shows up here and wins. Our own writes land back with
    // rawValue already equal to targetRaw, so they change nothing.
    onRawValueChanged: if (rawValue !== targetRaw) root.targetRaw = rawValue

    function resolveLevelIndex(value, thresholds) {
        let index = 0

        for (let i = 0; i < thresholds.length; i++) {
            if (value >= thresholds[i].threshold)
                index = i
            else
                break
        }

        return index
    }

    Process {
        id: setter
    }

    // ────── Device Discovery ──────
    // Indices under /sys/class/backlight are not fixed, and the name differs
    // per driver (intel_backlight, amdgpu_bl0, nvidia_0), so the directory is
    // read rather than hardcoded. The first entry wins; machines with a second
    // panel would need a Settings override.
    FolderListModel {
        id: backlightDirs

        folder: "file:///sys/class/backlight"
        showDirs: true
        showFiles: false
        showDotAndDotDot: false

        onStatusChanged: {
            if (status === FolderListModel.Ready && count > 0 && root.deviceName === "")
                root.deviceName = get(0, "fileName")
        }
    }

    FileView {
        path: root.deviceName
            ? "/sys/class/backlight/" + root.deviceName + "/max_brightness"
            : ""

        onLoaded: root.maxRaw = Number(text().trim())
    }

    FileView {
        id: actualFile

        path: root.deviceName
            ? "/sys/class/backlight/" + root.deviceName + "/actual_brightness"
            : ""

        // sysfs backlight does deliver inotify events, so this needs no timer
        // at all — verified against brightnessctl with no poller running.
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.rawValue = Number(text().trim())
    }

    // ────── Popup Backend ──────
    property bool nightQueryPending: false
    property bool identityQueryDone: false
    property bool temperatureQueryDone: false
    property bool queriedIdentity: true
    property int queriedTemperature: 0
    property bool nightQueryFailed: false

    property var currentDdcOp: null
    property var pendingDisplays: []
    property bool rediscoverRequested: false

    onDiscoveryActiveChanged: {
        if (!discoveryActive)
            return
        refreshNightLight()
        keyboardValue.reload()
        keyboardMaximum.reload()
        discoverDisplays()
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.discoveryActive
        onTriggered: root.refreshNightLight()
    }

    // The ThinkPad hotkey changes the LED through firmware without notifying
    // the brightness sysfs watcher. Read this one file only while the popup is
    // open, and read immediately after our own writes below.
    Timer {
        interval: 1000
        repeat: true
        running: root.discoveryActive && root.keyboardMax === 2
        onTriggered: keyboardValue.reload()
    }

    Connections {
        target: Hyprland
        enabled: root.discoveryActive
        function onRawEvent(event) {
            if (event.name.startsWith("monitoradded")
                    || event.name.startsWith("monitorremoved"))
                hotplugDelay.restart()
        }
    }

    Timer {
        id: hotplugDelay
        interval: 150
        onTriggered: root.discoverDisplays()
    }

    function refreshNightLight(force = false) {
        if ((!discoveryActive && !force) || nightQueryPending || nightSetter.running)
            return
        nightQueryPending = true
        identityQueryDone = false
        temperatureQueryDone = false
        nightQueryFailed = false
        identityQuery.running = true
        temperatureQuery.running = true
    }

    function runNightLightCommand(command) {
        if (!nightLightLoaded || nightLightBusy)
            return
        nightLightError = ""
        nightSetter.command = command
        nightSetter.running = true
    }

    function finishNightQuery() {
        if (!identityQueryDone || !temperatureQueryDone)
            return
        nightQueryPending = false
        if (nightQueryFailed) {
            nightLightLoaded = false
            nightLightError = "Unable to read night-light status."
            return
        }
        nightLightEnabled = !queriedIdentity
        nightTemperature = queriedTemperature
        nightLightLoaded = true
        if (nightLightError === "Unable to read night-light status.")
            nightLightError = ""
    }

    Process {
        id: identityQuery
        command: ["hyprctl", "hyprsunset", "identity", "get"]
        stdout: StdioCollector { id: identityOutput }
        onExited: code => {
            const output = identityOutput.text.trim().toLowerCase()
            if (code !== 0 || (output !== "true" && output !== "false"))
                root.nightQueryFailed = true
            else
                root.queriedIdentity = output === "true"
            root.identityQueryDone = true
            root.finishNightQuery()
        }
    }

    Process {
        id: temperatureQuery
        command: ["hyprctl", "hyprsunset", "temperature"]
        stdout: StdioCollector { id: temperatureOutput }
        onExited: code => {
            const output = temperatureOutput.text.trim()
            if (code !== 0 || !/^\d+$/.test(output))
                root.nightQueryFailed = true
            else
                root.queriedTemperature = Number(output)
            root.temperatureQueryDone = true
            root.finishNightQuery()
        }
    }

    Process {
        id: nightSetter
        stdout: StdioCollector { id: nightSetOutput }
        onExited: code => {
            // hyprctl can return exit code 0 even when its IPC reply is an
            // error string, so inspect the reply as well.
            if (code !== 0 || nightSetOutput.text.trim() !== "ok")
                root.nightLightError = "Unable to change night light."
            Qt.callLater(() => root.refreshNightLight(true))
        }
    }

    FileView {
        id: keyboardMaximum
        path: "/sys/class/leds/" + Settings.keyboardBacklightDevice + "/max_brightness"
        onLoaded: {
            const raw = text().trim()
            root.keyboardMax = /^\d+$/.test(raw) ? Number(raw) : -1
        }
    }

    FileView {
        id: keyboardValue
        path: "/sys/class/leds/" + Settings.keyboardBacklightDevice + "/brightness"
        onLoaded: {
            const raw = text().trim()
            root.keyboardLevel = /^\d+$/.test(raw) ? Number(raw) : -1
        }
    }

    function setKeyboardLevel(level) {
        if (!keyboardAvailable || keyboardBusy || level < 0 || level > 2)
            return
        if (level === keyboardLevel)
            return
        keyboardError = ""
        keyboardSetter.command = ["brightnessctl", "--device",
            Settings.keyboardBacklightDevice, "set", String(level)]
        keyboardSetter.running = true
    }

    Process {
        id: keyboardSetter
        onExited: code => {
            if (code !== 0)
                root.keyboardError = "Unable to change keyboard brightness."
            keyboardValue.reload()
        }
    }

    function parseDisplays(output) {
        const displays = []
        let display = null
        for (const line of output.split(/\r?\n/)) {
            if (/^Display\s+\d+\s*$/.test(line)) {
                if (display && display.bus >= 0 && display.name
                        && !display.connector.includes("eDP-"))
                    displays.push(display)
                display = {bus: -1, connector: "", name: ""}
            } else if (/^Invalid display/.test(line)) {
                if (display && display.bus >= 0 && display.name
                        && !display.connector.includes("eDP-"))
                    displays.push(display)
                display = null
            } else if (display) {
                let match = /^\s*I2C bus:\s*\/dev\/i2c-(\d+)\s*$/.exec(line)
                if (match) display.bus = Number(match[1])
                match = /^\s*DRM connector:\s*(\S+)\s*$/.exec(line)
                if (match) display.connector = match[1].replace(/^card\d+-/, "")
                match = /^\s*Monitor:\s*(.+)\s*$/.exec(line)
                if (match) {
                    const parts = match[1].trim().split(":")
                    display.name = parts[1] || parts[0]
                }
            }
        }
        if (display && display.bus >= 0 && display.name
                && !display.connector.includes("eDP-"))
            displays.push(display)
        return displays
    }

    function discoverDisplays() {
        if (!discoveryActive)
            return
        if (ddcBusy) {
            rediscoverRequested = true
            return
        }
        rediscoverRequested = false
        screenError = ""
        startDdc({kind: "detect"})
    }

    function startDdc(operation) {
        currentDdcOp = operation
        ddcBusy = true
        switch (operation.kind) {
        case "detect":
            ddcProcess.command = ["ddcutil", "detect", "--brief"]
            break
        case "get":
            ddcProcess.command = ["ddcutil", "--bus", String(operation.bus),
                "getvcp", "10", "--terse"]
            break
        case "set":
            ddcProcess.command = ["ddcutil", "--bus", String(operation.bus),
                "setvcp", "10", String(operation.raw)]
            break
        }
        ddcProcess.running = true
    }

    function advanceDdc() {
        if (ddcProcess.running)
            return
        if (pendingDisplays.length > 0) {
            const next = pendingDisplays.shift()
            startDdc({kind: "get", bus: next.bus,
                connector: next.connector, name: next.name,
                afterWrite: next.afterWrite || false})
            return
        }
        ddcBusy = false
        if (rediscoverRequested && discoveryActive)
            discoverDisplays()
    }

    function rowForBus(bus) {
        for (let i = 0; i < screenEntries.count; i++) {
            if (screenEntries.get(i).bus === bus)
                return i
        }
        return -1
    }

    function setExternalBrightness(bus, percent) {
        if (ddcBusy)
            return
        const rowIndex = rowForBus(bus)
        if (rowIndex < 0)
            return
        const row = screenEntries.get(rowIndex)
        if (!row.available || row.busy)
            return
        const clamped = Math.max(0, Math.min(100, Math.round(percent)))
        const raw = Math.round(clamped / 100 * row.max)
        screenError = ""
        screenEntries.setProperty(rowIndex, "busy", true)
        startDdc({kind: "set", bus, raw,
            connector: row.connector, name: row.name})
    }

    Process {
        id: ddcProcess
        stdout: StdioCollector { id: ddcOutput }
        onExited: code => {
            const op = root.currentDdcOp
            root.currentDdcOp = null
            if (!op)
                return

            if (op.kind === "detect") {
                for (let i = screenEntries.count - 1; i > 0; --i)
                    screenEntries.remove(i)
                root.pendingDisplays = code === 0
                    ? root.parseDisplays(ddcOutput.text) : []
                if (code !== 0)
                    root.screenError = "Unable to discover external displays."
            } else if (op.kind === "get") {
                const match = code === 0
                    ? /^VCP\s+10\s+C\s+(\d+)\s+(\d+)\s*$/m.exec(ddcOutput.text)
                    : null
                const rowIndex = root.rowForBus(op.bus)
                if (match && Number(match[2]) > 0) {
                    const maximum = Number(match[2])
                    const percentage = Math.round(Number(match[1]) / maximum * 100)
                    if (rowIndex >= 0) {
                        screenEntries.setProperty(rowIndex, "value", percentage)
                        screenEntries.setProperty(rowIndex, "max", maximum)
                        screenEntries.setProperty(rowIndex, "busy", false)
                        screenEntries.setProperty(rowIndex, "available", true)
                    } else {
                        screenEntries.append({kind: "external", bus: op.bus, connector: op.connector,
                            name: op.name, value: percentage, max: maximum,
                            busy: false, available: true})
                    }
                } else if (op.afterWrite && rowIndex >= 0) {
                    screenEntries.setProperty(rowIndex, "busy", false)
                    screenEntries.setProperty(rowIndex, "available", false)
                    root.screenError = "Unable to confirm " + op.name + " brightness."
                } else {
                    root.screenError = "Unable to read " + op.name + " brightness."
                }
            } else if (op.kind === "set") {
                if (code === 0) {
                    root.pendingDisplays.unshift({bus: op.bus,
                        connector: op.connector, name: op.name, afterWrite: true})
                } else {
                    const rowIndex = root.rowForBus(op.bus)
                    if (rowIndex >= 0)
                        screenEntries.setProperty(rowIndex, "busy", false)
                    root.screenError = "Unable to change " + op.name + " brightness."
                }
            }
            Qt.callLater(() => root.advanceDdc())
        }
    }

    // ────── Debug Trace ──────
    readonly property string logLine: {
        if (!Settings.bDebugTrace) return ""
        return "BACKLIGHT: " + value + "% " + level + " " + icon
            + " (" + targetRaw + "/" + maxRaw + " on " + deviceName + ")"
    }

    onLogLineChanged: if (Settings.bDebugTrace && available) console.log(logLine)
}
