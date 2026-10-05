pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

import qs

Singleton {
    id: root

    // ────── Public API ──────
    // {available, value, muted, state, level, headphones, icon, name, description}
    // `state` is what the view colours on: "default" or "muted". `level` is a
    // separate axis that only picks the icon, so a sink sitting at 0% but
    // unmuted still reads as "default".
    readonly property var sink: reading(Pipewire.defaultAudioSink, false)
    readonly property var source: reading(Pipewire.defaultAudioSource, true)

    // The bar needs only the two defaults above. The manager enables this
    // while its popup is open so the larger device/stream model is bound only
    // on demand.
    property bool discoveryActive: false

    // Audio presence is available before binding. Track audio nodes only;
    // volume and the complete property map become valid once ready is true.
    readonly property var audioNodes: Pipewire.nodes.values.filter(node =>
        node.audio !== null)

    readonly property var outputDeviceNodes: root.discoveryActive
        ? root.audioNodes.filter(node => !node.isStream && node.isSink)
        : []
    readonly property var inputDeviceNodes: root.discoveryActive
        ? root.audioNodes.filter(node => !node.isStream && !node.isSink)
        : []
    readonly property var applicationNodes: root.discoveryActive
        ? root.audioNodes.filter(node => node.ready && node.isStream
            && node.properties["media.class"] === "Stream/Output/Audio")
        : []

    readonly property var mediaPlayers: root.discoveryActive ? Mpris.players.values : []

    readonly property var outputDeviceSnapshots:
        root.makeDeviceEntries(root.outputDeviceNodes, false)
    readonly property var inputDeviceSnapshots:
        root.makeDeviceEntries(root.inputDeviceNodes, true)
    readonly property var applicationSnapshots:
        root.makeApplicationEntries()

    ListModel { id: outputDevices }
    ListModel { id: inputDevices }
    ListModel { id: applications }

    readonly property var outputDeviceModel: outputDevices
    readonly property var inputDeviceModel: inputDevices
    readonly property var applicationModel: applications

    property var sinkPortRecords: []
    property var sourcePortRecords: []

    onOutputDeviceSnapshotsChanged: {
        root.syncModel(outputDevices, root.outputDeviceSnapshots)
    }
    onInputDeviceSnapshotsChanged: root.syncModel(inputDevices,
        root.inputDeviceSnapshots)
    onApplicationSnapshotsChanged: {
        root.syncModel(applications, root.applicationSnapshots)
    }

    Process {
        id: sinkPortReader
        command: ["pactl", "--format=json", "list", "sinks"]
        running: true

        stdout: StdioCollector { id: sinkPortOutput }
        onExited: (code, status) => {
            if (code === 0)
                root.updatePortRecords(false, sinkPortOutput.text)
            if (portDemand.outputs)
                portDebounce.restart()
        }
    }

    Process {
        id: sourcePortReader
        command: ["pactl", "--format=json", "list", "sources"]
        running: false

        stdout: StdioCollector { id: sourcePortOutput }
        onExited: (code, status) => {
            if (code === 0 && root.discoveryActive)
                root.updatePortRecords(true, sourcePortOutput.text)
            if (portDemand.inputs && root.discoveryActive)
                portDebounce.restart()
        }
    }

    // Bind only devices and playback streams. Capture streams include
    // pavucontrol's peak meters, which do not belong in the mixer and can
    // expose inconsistent channel metadata. isStream/isSink are available
    // before binding; node.properties and node.ready are not.
    PwObjectTracker {
        objects: root.discoveryActive
            ? root.audioNodes.filter(node => !node.isStream || node.isSink)
            : [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Component.onCompleted: root.refreshModels()

    onDiscoveryActiveChanged: {
        root.refreshModels()
        if (root.discoveryActive) {
            root.requestPorts(true, true)
        } else {
            portDemand.inputs = false
            root.sourcePortRecords = []
        }
    }

    function refreshModels() {
        syncModel(outputDevices, root.outputDeviceSnapshots)
        syncModel(inputDevices, root.inputDeviceSnapshots)
        syncModel(applications, root.applicationSnapshots)
    }

    function syncModel(model, entries) {
        const ids = new Set(entries.map(entry => entry.id))

        for (let i = model.count - 1; i >= 0; --i) {
            if (!ids.has(model.get(i).id))
                model.remove(i)
        }

        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i]
            let existing = i

            while (existing < model.count && model.get(existing).id !== entry.id)
                ++existing

            if (existing === model.count)
                model.insert(i, entry)
            else {
                if (existing !== i)
                    model.move(existing, i, 1)

                for (const key of Object.keys(entry)) {
                    if (model.get(i)[key] !== entry[key])
                        model.setProperty(i, key, entry[key])
                }
            }
        }
    }

    // ────── Actions ──────
    function setVolume(percent) {
        const audio = audioOf(Pipewire.defaultAudioSink)

        if (audio)
            audio.volume = clampPercent(percent) / 100
    }

    // `steps` is a count, not a percentage: the view passes +1 / -1 and the
    // size of a step stays configuration, not UI.
    function stepVolume(steps) {
        setVolume(root.sink.value + steps * Settings.volumeStepPercentage)
    }

    function toggleMute() {
        const audio = audioOf(Pipewire.defaultAudioSink)

        if (audio)
            audio.muted = !audio.muted
    }

    function setSourceVolume(percent) {
        const audio = audioOf(Pipewire.defaultAudioSource)

        if (audio)
            audio.volume = clampPercent(percent) / 100
    }

    function stepSourceVolume(steps) {
        setSourceVolume(root.source.value + steps * Settings.volumeStepPercentage)
    }

    function toggleSourceMute() {
        const audio = audioOf(Pipewire.defaultAudioSource)

        if (audio)
            audio.muted = !audio.muted
    }

    function setNodeVolume(node, percent) {
        const audio = audioOf(node)

        if (audio)
            audio.volume = clampPercent(percent) / 100
    }

    function nodeForId(nodeId) {
        const id = Number(String(nodeId).split(":")[0])
        for (const node of root.audioNodes) {
            if (node.id === id)
                return node
        }
        return null
    }

    function setEntryVolume(nodeId, percent) {
        root.setNodeVolume(root.nodeForId(nodeId), percent)
    }

    function setNodeMuted(node, muted) {
        const audio = audioOf(node)

        if (audio)
            audio.muted = muted
    }

    function setEntryMuted(nodeId, muted) {
        root.setNodeMuted(root.nodeForId(nodeId), muted)
    }

    function selectOutput(node) {
        if (node && node.ready)
            Pipewire.preferredDefaultAudioSink = node
    }

    function selectInput(node) {
        if (node && node.ready)
            Pipewire.preferredDefaultAudioSource = node
    }

    function selectOutputById(nodeId) {
        root.selectEntry(nodeId, false)
    }

    function selectInputById(nodeId) {
        root.selectEntry(nodeId, true)
    }

    function selectEntry(entryId, isInput) {
        const node = root.nodeForId(entryId)
        const port = root.entryPort(entryId)

        if (!node || !node.ready || node.isStream || node.isSink === isInput)
            return

        if (port) {
            const record = root.portRecordFor(node, isInput)
            const route = record ? record.ports.find(item => item.name === port) : null
            if (!route || route.availability === "not available")
                return
            if (portSelector.running)
                return
            portSelector.selectedId = entryId
            portSelector.isInput = isInput
            portSelector.command = ["pactl",
                isInput ? "set-source-port" : "set-sink-port",
                node.name, port]
            portSelector.running = true
            return
        }

        if (isInput)
            root.selectInput(node)
        else
            root.selectOutput(node)
    }

    function entryPort(entryId) {
        const parts = String(entryId).split(":")
        return parts.length > 1 ? parts.slice(1).join(":") : ""
    }

    function updatePortRecords(isInput, json) {
        let records = []

        try {
            records = JSON.parse(json).map(item => ({
                nodeName: item.name,
                activePort: item.active_port || "",
                hasPorts: (item.ports || []).length > 0,
                // Unavailable routes are not choices. Retain the no-port case
                // so portless devices can still be represented by their node.
                ports: (item.ports || []).filter(port =>
                    port.availability !== "not available")
            }))
        } catch (error) {
            console.warn("Could not read audio ports:", error)
            return
        }

        if (isInput)
            root.sourcePortRecords = records
        else
            root.sinkPortRecords = records

        root.refreshModels()
    }

    function portRecordFor(node, isInput) {
        const records = isInput ? root.sourcePortRecords : root.sinkPortRecords

        for (const record of records) {
            if (record.nodeName === node.name)
                return record
        }

        return null
    }

    function makeDeviceEntries(nodes, isInput) {
        const entries = []

        for (const node of nodes) {
            const record = root.portRecordFor(node, isInput)
            const ports = record ? record.ports : []

            if (ports.length === 0) {
                if (!record || !record.hasPorts)
                    entries.push(root.deviceReading(node, isInput, null, ""))
                continue
            }

            for (const port of ports)
                entries.push(root.deviceReading(node, isInput, port,
                    record.activePort))
        }

        return entries
    }

    function deviceReading(node, isInput, port, activePort) {
        const audio = audioOf(node)
        const headphones = !isInput && (port
            ? /headphone|headset/i.test(port.type)
                || /headphone|headset/i.test(port.name)
            : isHeadphoneNode(node))
        const deviceName = node.nickname || node.description || node.name
        const properties = node.properties || ({})
        const internal = (properties["device.form_factor"]
            || properties["device.form-factor"]) === "internal"
        const record = root.portRecordFor(node, isInput)
        // Internal routes need labels such as Speakers/Headphones. External
        // devices keep their identity; append a route only when needed to
        // distinguish multiple ports belonging to that same device.
        const name = port && internal ? (port.description || deviceName)
            : deviceName + (port && record && record.ports.length > 1
                ? " — " + (port.description || port.name) : "")

        return {
            id: String(node.id) + (port ? ":" + port.name : ""),
            nodeId: String(node.id),
            portName: port ? port.name : "",
            name: name,
            nodeName: node.name,
            description: node.description || node.name,
            icon: resolveIcon(audio ? resolveLevelIndex(
                Math.round(audio.volume * 100), Settings.volumeLevelThresholds)
                : 0, audio ? audio.muted : true,
                headphones, isInput),
            iconName: deviceIconName(node, isInput),
            value: audio ? Math.round(audio.volume * 100) : 0,
            muted: audio ? audio.muted : true,
            state: audio && !audio.muted ? "default" : "muted",
            canSelect: node.ready && (!port || port.availability !== "not available"),
            isDefault: node === (isInput
                ? Pipewire.defaultAudioSource : Pipewire.defaultAudioSink)
                && (!port || activePort === port.name),
            isInput: isInput
        }
    }

    function applicationReading(node, player) {
        const audio = audioOf(node)
        const properties = node.properties || ({})
        const name = properties["application.name"] || node.description || node.name
        const icon = root.applicationIcon(properties, player)

        return {
            id: String(node.id),
            name: name,
            iconName: icon.name,
            iconSource: icon.source,
            hasStream: true,
            isInput: false,
            isOutput: true,
            value: audio ? Math.round(audio.volume * 100) : 0,
            muted: audio ? audio.muted : true,
            state: audio && !audio.muted ? "default" : "muted"
        }
    }

    function playerForNode(node) {
        const properties = node.properties || ({})
        const names = [properties["application.name"],
            properties["application.process.binary"], node.name]
            .filter(Boolean).map(name => String(name).toLowerCase())

        return root.mediaPlayers.find(player =>
            names.includes(player.identity.toLowerCase())
            || (player.desktopEntry && names.includes(player.desktopEntry.toLowerCase())))
            || null
    }

    function makeApplicationEntries() {
        const matchedPlayers = new Set()
        const entries = root.applicationNodes.map(node => {
            const player = root.playerForNode(node)
            if (player)
                matchedPlayers.add(player.dbusName)
            return root.applicationReading(node, player)
        })

        // Media players can exist before creating an audio stream. Show their
        // identity via MPRIS but disable mixer controls until a stream exists.
        for (const player of root.mediaPlayers) {
            if (!player.identity || matchedPlayers.has(player.dbusName))
                continue
            const icon = root.applicationIcon({}, player)
            entries.push({
                id: "player:" + player.dbusName,
                name: player.identity,
                iconName: icon.name,
                iconSource: icon.source,
                hasStream: false,
                isInput: false,
                isOutput: true,
                value: 0,
                muted: false,
                state: "default"
            })
        }
        return entries
    }

    function applicationIcon(properties, player) {
        // Desktop entries provide the real installed icon even when stream
        // metadata is absent (Spotify) or uses a different property spelling.
        const ids = [player ? player.desktopEntry : "",
            properties["application.id"], properties["application.process.binary"],
            properties["application.name"], player ? player.identity : ""]
        for (const id of ids) {
            if (!id)
                continue
            const entry = DesktopEntries.byId(String(id))
                || DesktopEntries.heuristicLookup(String(id))
            if (entry && entry.icon) {
                const source = Quickshell.iconPath(entry.icon, true)
                if (source)
                    return { name: entry.icon, source: source }
            }
        }
        for (const name of [properties["application.icon-name"],
                properties["application.icon_name"]]) {
            if (name) {
                const source = Quickshell.iconPath(String(name), true)
                if (source)
                    return { name: String(name), source: source }
            }
        }
        return { name: "", source: "" }
    }

    function deviceIconName(node, isInput) {
        const properties = node.properties || ({})
        if (isInput)
            return properties["device.icon-name"] || "audio-input-microphone"

        return properties["device.icon-name"] || (isHeadphoneNode(node)
            ? "audio-headphones" : "audio-speakers")
    }

    // ────── Internals ──────
    function audioOf(node) {
        return node && node.ready && node.audio ? node.audio : null
    }

    function clampPercent(percent) {
        return Math.max(0, Math.min(100, Math.round(percent)))
    }

    function reading(node, isInput) {
        const audio = audioOf(node)

        if (!audio) {
            return {
                available: false,
                value: 0,
                muted: true,
                state: "muted",
                level: Settings.volumeLevelThresholds[0].state,
                headphones: false,
                icon: isInput ? Settings.volumeInputMicOffIcon : Settings.volumeMutedIcon,
                name: "",
                description: ""
            }
        }

        const percent = Math.round(audio.volume * 100)
        const muted = audio.muted
        const headphones = !isInput && isHeadphoneNode(node)
        const index = resolveLevelIndex(percent, Settings.volumeLevelThresholds)

        return {
            available: true,
            value: percent,
            muted: muted,
            state: muted ? "muted" : "default",
            level: Settings.volumeLevelThresholds[index].state,
            headphones: headphones,
            icon: resolveIcon(index, muted, headphones, isInput),
            name: node.name,
            description: node.description
        }
    }

    // Returns the index rather than the state name, so volumeCtrlIcon and
    // volumeLevelThresholds stay locked together — add a threshold and you
    // must add the icon that goes with it.
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

    function resolveIcon(levelIndex, muted, headphones, isInput) {
        if (isInput)
            return muted ? Settings.volumeInputMicOffIcon : Settings.volumeInputMicOnIcon

        if (headphones)
            return muted ? Settings.volumeHeadphoneMutedIcon : Settings.volumeHeadphoneIcon

        if (muted)
            return Settings.volumeMutedIcon

        return Settings.volumeCtrlIcon[Math.min(levelIndex, Settings.volumeCtrlIcon.length - 1)]
    }

    // Bluetooth and USB headsets say so on the node itself.
    function isHeadphoneNode(node) {
        const properties = node.properties

        if (properties) {
            if (properties["device.api"] === "bluez5"
                || properties["device.bus"] === "bluetooth")
                return true

            const formFactor = properties["device.form-factor"] || properties["device.form_factor"]

            if (formFactor === "headphone" || formFactor === "headset")
                return true

            const iconName = properties["device.icon-name"] || properties["device.icon_name"]

            if (iconName === "audio-headphones" || iconName === "audio-headset")
                return true
        }

        // The built-in 3.5mm jack is invisible on the node: inserting a plug
        // switches the ALSA *route* and leaves every node property untouched —
        // verified against a real insertion, not just a forced port. The active
        // port is the only thing that moves, and PipeWire does not publish it,
        // so it comes from pactl instead.
        const record = root.portRecordFor(node, false)
        return record !== null && /headphone|headset/i.test(record.activePort)
    }

    // ────── Hardware Routes ──────
    // Quickshell exposes nodes but not ALSA routes. Reuse one event listener
    // and coalesce finite route queries; no timer runs while audio is idle.
    readonly property string activePort: {
        const node = Pipewire.defaultAudioSink
        const record = node ? root.portRecordFor(node, false) : null
        return record ? record.activePort : ""
    }

    QtObject {
        id: portDemand
        property bool outputs: false
        property bool inputs: false
    }

    function requestPorts(outputsNeeded, inputsNeeded) {
        portDemand.outputs = portDemand.outputs || outputsNeeded
        portDemand.inputs = portDemand.inputs || (inputsNeeded && root.discoveryActive)
        portDebounce.restart()
    }

    Timer {
        id: portDebounce
        interval: 150
        onTriggered: {
            if (portDemand.outputs && !sinkPortReader.running) {
                portDemand.outputs = false
                sinkPortReader.running = true
            }
            if (portDemand.inputs && root.discoveryActive && !sourcePortReader.running) {
                portDemand.inputs = false
                sourcePortReader.running = true
            }
        }
    }

    Process {
        id: portSelector
        property string selectedId: ""
        property bool isInput: false
        stderr: StdioCollector { id: selectionError }
        onExited: (code, status) => {
            if (code === 0) {
                const node = root.nodeForId(selectedId)
                if (isInput && node !== Pipewire.defaultAudioSource)
                    root.selectInput(node)
                else if (!isInput && node !== Pipewire.defaultAudioSink)
                    root.selectOutput(node)
            } else {
                console.warn("Could not select audio port:", selectionError.text.trim())
            }
            root.requestPorts(!isInput, isInput)
        }
    }

    Process {
        command: ["pactl", "subscribe"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                const card = data.indexOf("on card") >= 0
                const output = card || data.indexOf("on sink #") >= 0
                const input = card || data.indexOf("on source #") >= 0
                if (output || input)
                    root.requestPorts(output, input)
            }
        }
    }

    // ────── Debug Trace ──────
    readonly property string logLine: {
        if (!Settings.bDebugTrace) return ""
        return "AUDIO: sink " + sink.value + "% " + sink.state
            + " level=" + sink.level + " " + sink.icon
            + (sink.headphones ? " [headphones]" : "") + " port=" + activePort
            + " <" + sink.description + ">"
            + " | source " + source.value + "% " + source.state + " " + source.icon
    }

    onLogLineChanged: if (Settings.bDebugTrace && Pipewire.ready) console.log(logLine)
}
