pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

import qs

// NetworkManager-backed state for the configured Wi-Fi and Ethernet devices.
Singleton {
    id: root

    readonly property string wifiInterface: Settings.networkWifiInterface
    readonly property string ethernetInterface: Settings.networkEthInterface
    readonly property var wifiDevice: {
        const devices = Networking.devices.values
        for (let i = 0; i < devices.length; ++i) {
            if (devices[i].type === DeviceType.Wifi
                    && devices[i].name === root.wifiInterface)
                return devices[i]
        }
        return null
    }
    onWifiDeviceChanged: {
        if (priv.operationId.startsWith("wifi:")
                && (!root.wifiDevice || !priv.operationNetwork
                    || priv.operationNetwork.device !== root.wifiDevice))
            finishOperation("The Wi-Fi device changed.")
        if (priv.initialized) refreshActiveProfiles()
    }
    readonly property var ethernetDevice: {
        const devices = Networking.devices.values
        for (let i = 0; i < devices.length; ++i) {
            if (devices[i].type === DeviceType.Wired
                    && devices[i].name === root.ethernetInterface)
                return devices[i]
        }
        return null
    }
    onEthernetDeviceChanged: {
        if (priv.operationId.startsWith("wired:")
                && (!root.ethernetDevice || !priv.operationNetwork
                    || priv.operationNetwork.device !== root.ethernetDevice))
            finishOperation("The Ethernet device changed.")
        if (priv.initialized) refreshActiveProfiles()
    }
    readonly property bool wifiPresent: root.wifiDevice !== null
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiAvailable: root.wifiPresent && root.wifiHardwareEnabled
    readonly property bool wifiToggleBusy: priv.wifiRequested
    readonly property string wifiErrorMessage: priv.wifiError
    readonly property bool wifiConnected: root.wifiAvailable && root.wifiEnabled
        && root.wifiDevice.connected

    readonly property var connectedWifiNetwork: {
        if (!root.wifiConnected) return null
        const networks = root.wifiDevice.networks.values
        for (let i = 0; i < networks.length; ++i) {
            if (networks[i].connected) return networks[i]
        }
        return null
    }
    readonly property string wifiVisibilitySignature: {
        if (!root.wifiDevice) return ""
        return root.wifiDevice.networks.values.map(network =>
            network.name + ":" + (network.signalStrength > 0)).sort().join("\n")
    }
    onWifiVisibilitySignatureChanged: {
        if (root.discoveryActive) refreshVisibleNetworks()
    }
    readonly property int wifiStrength: root.connectedWifiNetwork
        ? Math.round(root.connectedWifiNetwork.signalStrength * 100) : 0

    readonly property bool ethernetConnected: root.ethernetDevice !== null
        && root.ethernetDevice.connected
    function wifiSignalLevel(strength) {
        let level = 0
        for (let i = 0; i < Settings.wifiSignalThresholds.length; ++i) {
            if (strength >= Settings.wifiSignalThresholds[i].threshold)
                level = i
        }
        return level
    }
    readonly property string icon: {
        if (root.ethernetConnected) return Settings.networkEthIcon
        if (!root.wifiAvailable || !root.wifiEnabled)
            return Settings.networkWifiOffIcon
        if (!root.wifiConnected) return Settings.networkWiFiOnIcon[0]

        const level = root.wifiSignalLevel(root.wifiStrength)
        return Settings.networkWiFiOnIcon[
            Math.min(level + 1, Settings.networkWiFiOnIcon.length - 1)]
    }

    // One active-connection lookup fills the profile identity Quickshell 0.3.1
    // does not expose on Network. It runs on native connection changes.
    readonly property string connectionSignature: {
        const wifi = root.wifiDevice
        const ethernet = root.ethernetDevice
        return (wifi ? wifi.name + ":" + wifi.connected : "") + ";"
            + (ethernet ? ethernet.name + ":" + ethernet.connected : "")
    }
    onConnectionSignatureChanged: {
        if (!priv.initialized) return
        refreshActiveProfiles()
        if (root.connectedWifiNetwork) {
            const entryId = wifiId(root.connectedWifiNetwork)
            if (priv.entryErrors[entryId]) clearEntryError(entryId)
        }
    }

    readonly property var entrySnapshots: {
        const active = []
        const available = []
        const device = root.wifiDevice
        if (device && root.wifiEnabled && root.wifiHardwareEnabled) {
            for (const network of device.networks.values) {
                const entryId = wifiId(network)
                const visible = root.discoveryActive && priv.visibleSsids !== null
                    && priv.visibleSsids.indexOf(network.name) !== -1
                if (!network.connected && !visible && priv.operationId !== entryId)
                    continue
                const profiles = network.nmSettings.slice()
                    .filter(profile => profile !== null)
                    .sort((a, b) => a.uuid.localeCompare(b.uuid))
                const activeUuid = priv.activeProfiles[device.name] || ""
                const profile = profiles.find(p => p.uuid === activeUuid) || profiles[0] || null
                const security = securityName(network.security)
                const state = entryState(entryId, network)
                const row = makeEntry(entryId, "wifi", network.name, device.name,
                    profile ? profile.uuid : "", security,
                    Math.round(network.signalStrength * 100), state)
                ;(network.connected || state === "Disconnecting" ? active : available).push(row)
            }
        }
        const wired = root.ethernetDevice
        if (wired && wired.hasLink && wired.network) {
            const network = wired.network
            const profiles = network.nmSettings.slice()
                .filter(profile => profile !== null)
                .sort((a, b) => a.uuid.localeCompare(b.uuid))
            const activeUuid = priv.activeProfiles[wired.name] || ""
            let foundActive = false
            for (const profile of profiles) {
                const entryId = wiredId(wired.name, profile.uuid)
                const connected = wired.connected && profile.uuid === activeUuid
                if (connected) foundActive = true
                const state = entryState(entryId, connected ? network : null)
                const row = makeEntry(entryId, "ethernet", profile.id, wired.name,
                    profile.uuid, "wired", 0, state)
                ;(connected || state === "Disconnecting" ? active : available).push(row)
            }
            if (wired.connected && !foundActive) {
                const entryId = wiredId(wired.name, "active")
                active.push(makeEntry(entryId, "ethernet", network.name || wired.name,
                    wired.name, "", "wired", 0, "Connected"))
            }
        }
        if (priv.operationId && priv.operationRow
                && !active.concat(available).some(row => row.entryId === priv.operationId)) {
            const previous = priv.operationRow
            const state = priv.operationMode === "disconnect" ? "Disconnecting" : "Connecting"
            const row = makeEntry(previous.entryId, previous.kind, previous.name,
                previous.interfaceName, previous.profileUuid, previous.security,
                previous.signalStrength, state)
            ;(state === "Disconnecting" ? active : available).push(row)
        }
        return {active: active, available: available}
    }
    readonly property var activeConnections: activeModel
    readonly property var availableConnections: availableModel
    onEntrySnapshotsChanged: {
        syncModel(activeModel, root.entrySnapshots.active)
        syncModel(availableModel, root.entrySnapshots.available)
    }
    ListModel { id: activeModel }
    ListModel { id: availableModel }

    function wifiId(network) { return "wifi:" + encodeURIComponent(network.name) }
    function wiredId(iface, uuid) {
        return "wired:" + encodeURIComponent(iface) + ":" + uuid
    }
    function securityName(security) {
        switch (security) {
        case WifiSecurityType.Open: return "open"
        case WifiSecurityType.WpaPsk:
        case WifiSecurityType.Wpa2Psk:
        case WifiSecurityType.Sae: return "personal"
        case WifiSecurityType.WpaEap:
        case WifiSecurityType.Wpa2Eap:
        case WifiSecurityType.Wpa3SuiteB192: return "enterprise"
        default: return "unsupported"
        }
    }
    function entryState(entryId, network) {
        if (priv.operationId === entryId) {
            if (priv.operationMode === "disconnect") return "Disconnecting"
            return "Connecting"
        }
        if (!network) return "Available"
        switch (network.state) {
        case ConnectionState.Connecting: return "Connecting"
        case ConnectionState.Disconnecting: return "Disconnecting"
        case ConnectionState.Connected: return "Connected"
        default: return network.connected ? "Connected" : "Available"
        }
    }
    function makeEntry(entryId, kind, name, iface, uuid, security, strength, state) {
        const busy = priv.operationId !== ""
        const prompt = priv.operationId === entryId
            && priv.operationStatus === "PasswordRequired"
        const error = priv.entryErrors[entryId] || ""
        return {
            entryId: entryId,
            kind: kind,
            name: name,
            interfaceName: iface,
            profileUuid: uuid,
            security: security,
            signalStrength: strength,
            state: state,
            status: prompt ? "PasswordRequired" : "",
            errorMessage: error,
            canConnect: state === "Available" && !busy
                && (kind === "ethernet" || security === "open"
                    || security === "personal" || uuid !== ""),
            canDisconnect: state === "Connected" && !busy,
            canSubmitPassword: prompt,
            canCancel: prompt,
            canEdit: uuid !== ""
        }
    }
    function syncModel(model, entries) {
        const ids = new Set(entries.map(entry => entry.entryId))
        for (let i = model.count - 1; i >= 0; --i) {
            if (!ids.has(model.get(i).entryId)) model.remove(i)
        }
        for (let i = 0; i < entries.length; ++i) {
            const row = entries[i]
            let existing = i
            while (existing < model.count && model.get(existing).entryId !== row.entryId)
                ++existing
            if (existing === model.count) model.insert(i, row)
            else {
                if (existing !== i) model.move(existing, i, 1)
                for (const key of Object.keys(row)) {
                    if (model.get(i)[key] !== row[key]) model.setProperty(i, key, row[key])
                }
            }
        }
    }

    // The popup owns discovery demand. No scans are requested by the bar.
    property bool discoveryActive: false
    readonly property bool scanning: root.wifiDevice !== null
        && root.wifiDevice.scannerEnabled
    readonly property bool refreshing: visibleQuery.running
    readonly property string scanErrorMessage: priv.scanError
    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.discoveryActive && root.wifiAvailable && root.wifiEnabled
        when: root.wifiDevice !== null
    }
    onDiscoveryActiveChanged: {
        if (root.discoveryActive) refreshVisibleNetworks()
        else priv.visibleSsids = null
    }
    function escapedFields(line) {
        const fields = []
        let field = ""
        for (let i = 0; i < line.length; ++i) {
            if (line[i] === "\\" && i + 1 < line.length
                    && (line[i + 1] === ":" || line[i + 1] === "\\"))
                field += line[++i]
            else if (line[i] === ":") { fields.push(field); field = "" }
            else field += line[i]
        }
        fields.push(field)
        return fields
    }
    function refreshVisibleNetworks(forceScan = false) {
        if (!root.discoveryActive || !root.wifiAvailable || !root.wifiEnabled)
            return
        if (visibleQuery.running) {
            priv.visibleQueryAgain = true
            priv.forceVisibleQueryAgain = priv.forceVisibleQueryAgain || forceScan
            return
        }
        visibleQuery.command = ["nmcli", "--colors", "no", "--terse", "--escape", "yes",
            "--fields", "SSID", "device", "wifi", "list", "ifname",
            root.wifiInterface, "--rescan", forceScan ? "yes" : "no"]
        visibleQuery.running = true
    }
    function forceWifiScan() {
        if (!root.discoveryActive || !root.wifiAvailable || !root.wifiEnabled)
            return
        priv.scanError = ""
        root.refreshVisibleNetworks(true)
    }
    Process {
        id: visibleQuery
        stdout: StdioCollector { id: visibleOutput }
        onExited: (code, status) => {
            if (!root.discoveryActive) {
                priv.visibleQueryAgain = false
                priv.forceVisibleQueryAgain = false
                return
            }
            if (code !== 0 || status !== 0) {
                priv.scanError = "Could not list nearby Wi-Fi networks."
            } else {
                priv.scanError = ""
                const names = []
                for (const line of visibleOutput.text.split("\n")) {
                    if (!line) continue
                    const name = root.escapedFields(line)[0]
                    if (name && names.indexOf(name) === -1) names.push(name)
                }
                priv.visibleSsids = names
            }
            if (priv.visibleQueryAgain) {
                const forceScan = priv.forceVisibleQueryAgain
                priv.visibleQueryAgain = false
                priv.forceVisibleQueryAgain = false
                Qt.callLater(() => root.refreshVisibleNetworks(forceScan))
            }
        }
    }

    function refreshActiveProfiles() {
        if (activeQuery.running) { priv.activeQueryAgain = true; return }
        activeQuery.running = true
    }
    Process {
        id: activeQuery
        command: ["nmcli", "--colors", "no", "--terse", "--escape", "yes",
            "--fields", "UUID,DEVICE", "connection", "show", "--active"]
        stdout: StdioCollector { id: activeOutput }
        onExited: (code, status) => {
            if (code === 0 && status === 0) {
                const byDevice = ({})
                for (const line of activeOutput.text.split("\n")) {
                    if (!line) continue
                    const fields = root.escapedFields(line)
                    if (fields.length === 2) byDevice[fields[1]] = fields[0]
                }
                priv.activeProfiles = byDevice
                for (const iface of Object.keys(byDevice)) {
                    const entryId = wiredId(iface, byDevice[iface])
                    if (priv.entryErrors[entryId]) clearEntryError(entryId)
                }
            }
            if (priv.activeQueryAgain) {
                priv.activeQueryAgain = false
                Qt.callLater(root.refreshActiveProfiles)
            }
        }
    }

    function setWifiEnabled(enabled) {
        if (!root.wifiAvailable || priv.wifiRequested) return
        if (root.wifiEnabled === enabled) return
        priv.wifiError = ""
        priv.expectedWifi = enabled
        priv.wifiRequested = true
        wifiTimeout.restart()
        Networking.wifiEnabled = enabled
    }
    function toggleWifi() { root.setWifiEnabled(!root.wifiEnabled) }

    function findEntry(entryId) {
        for (const model of [activeModel, availableModel]) {
            for (let i = 0; i < model.count; ++i) {
                const entry = model.get(i)
                if (entry.entryId === entryId) return entry
            }
        }
        return null
    }
    function nativeNetwork(entry) {
        if (entry.kind === "wifi") {
            if (!root.wifiDevice) return null
            for (const network of root.wifiDevice.networks.values) {
                if (wifiId(network) === entry.entryId) return network
            }
            return null
        }
        return root.ethernetDevice
            && root.ethernetDevice.name === entry.interfaceName
            ? root.ethernetDevice.network : null
    }
    function setEntryError(entryId, message) {
        const errors = Object.assign({}, priv.entryErrors)
        if (message) errors[entryId] = message
        else delete errors[entryId]
        priv.entryErrors = errors
    }
    function clearEntryError(entryId) { setEntryError(entryId, "") }
    function beginOperation(entryId, network, mode) {
        if (priv.operationId) return false
        setEntryError(entryId, "")
        const entry = findEntry(entryId)
        priv.operationRow = entry ? {
            entryId: entry.entryId, kind: entry.kind, name: entry.name,
            interfaceName: entry.interfaceName, profileUuid: entry.profileUuid,
            security: entry.security, signalStrength: entry.signalStrength
        } : null
        priv.operationNetwork = network
        priv.operationId = entryId
        priv.operationMode = mode
        priv.operationStatus = ""
        priv.passwordSubmitted = false
        return true
    }
    function finishOperation(error = "") {
        const entryId = priv.operationId
        operationTimeout.stop()
        priv.operationId = ""
        priv.operationMode = ""
        priv.operationStatus = ""
        priv.operationNetwork = null
        priv.operationRow = null
        priv.passwordSubmitted = false
        if (entryId && error) setEntryError(entryId, error)
        root.refreshActiveProfiles()
        if (root.discoveryActive) root.refreshVisibleNetworks()
    }
    function connectEntry(entryId) {
        const entry = findEntry(entryId)
        if (!entry || !entry.canConnect || priv.operationId) return
        const network = nativeNetwork(entry)
        if (!network || network.connected) return
        if (!beginOperation(entryId, network, "connect")) return
        if (entry.kind === "wifi" && entry.security === "personal"
                && !entry.profileUuid) {
            priv.operationStatus = "PasswordRequired"
            return
        }
        operationTimeout.interval = 90000
        operationTimeout.restart()
        if (entry.profileUuid) {
            const profile = network.nmSettings.find(p => p !== null
                && p.uuid === entry.profileUuid)
            if (!profile) {
                finishOperation("The saved connection is no longer available.")
                return
            }
            network.connectWithSettings(profile)
        } else network.connect()
    }
    function submitPassword(entryId, password) {
        if (priv.operationId !== entryId
                || priv.operationStatus !== "PasswordRequired" || !password) return
        const network = priv.operationNetwork
        if (!network) {
            finishOperation("The network is no longer available.")
            return
        }
        priv.passwordSubmitted = true
        priv.operationStatus = ""
        operationTimeout.interval = 90000
        operationTimeout.restart()
        network.connectWithPsk(password)
        password = ""
    }
    function disconnectEntry(entryId) {
        const entry = findEntry(entryId)
        if (!entry || !entry.canDisconnect || priv.operationId) return
        const network = nativeNetwork(entry)
        if (!network || !network.connected) return
        if (!beginOperation(entryId, network, "disconnect")) return
        operationTimeout.interval = 15000
        operationTimeout.restart()
        network.disconnect()
    }
    function cancelConnection(entryId) {
        // A pending password prompt is local. Cancelling an in-flight activation
        // would require deactivating a specific NM ActiveConnection, unavailable
        // through this API; the UI therefore cannot claim to cancel that work.
        if (priv.operationId === entryId
                && priv.operationStatus === "PasswordRequired") finishOperation()
    }
    function editConnection(entryId) {
        const entry = findEntry(entryId)
        if (entry && entry.canEdit && entry.profileUuid)
            Actions.networkManager(entry.profileUuid)
    }
    function openSettings() { Actions.networkManager() }

    function checkOperation() {
        const network = priv.operationNetwork
        if (!network || !priv.operationId || priv.operationStatus) return
        if (priv.operationMode === "connect" && network.connected)
            finishOperation()
        else if (priv.operationMode === "disconnect"
                && network.state === ConnectionState.Disconnected)
            finishOperation()
    }
    function failOperation(reason) {
        if (!priv.operationId || priv.operationMode !== "connect") return
        if (reason === ConnectionFailReason.NoSecrets && !priv.passwordSubmitted
                && securityName(priv.operationNetwork.security) === "personal") {
            operationTimeout.stop()
            priv.operationStatus = "PasswordRequired"
            return
        }
        finishOperation("Connection failed: " + ConnectionFailReason.toString(reason))
    }
    Connections {
        target: priv.operationNetwork
        function onStateChanged() { root.checkOperation() }
        function onConnectedChanged() { root.checkOperation() }
        function onConnectionFailed(reason) { root.failOperation(reason) }
    }
    Timer {
        id: operationTimeout
        onTriggered: root.finishOperation("NetworkManager did not complete the action in time.")
    }

    QtObject {
        id: priv
        property bool initialized: false
        property var activeProfiles: ({})
        property bool activeQueryAgain: false
        property var visibleSsids: null
        property bool visibleQueryAgain: false
        property bool forceVisibleQueryAgain: false
        property string scanError: ""
        property string operationId: ""
        property string operationMode: ""
        property string operationStatus: ""
        property var operationNetwork: null
        property var operationRow: null
        property bool passwordSubmitted: false
        property var entryErrors: ({})
        property bool wifiRequested: false
        property bool expectedWifi: false
        property string wifiError: ""
    }
    Timer {
        id: wifiTimeout
        interval: 5000
        onTriggered: {
            priv.wifiRequested = false
            priv.wifiError = "NetworkManager did not confirm the Wi-Fi change."
        }
    }
    Connections {
        target: Networking
        function onWifiEnabledChanged() {
            if (!root.wifiEnabled && priv.operationId.startsWith("wifi:"))
                root.finishOperation("Wi-Fi was turned off.")
            if (priv.wifiRequested && root.wifiEnabled === priv.expectedWifi) {
                wifiTimeout.stop()
                priv.wifiRequested = false
                priv.wifiError = ""
            }
        }
        function onWifiHardwareEnabledChanged() {
            if (!root.wifiHardwareEnabled && priv.operationId.startsWith("wifi:"))
                root.finishOperation("Wi-Fi is blocked by hardware.")
        }
    }

    Component.onCompleted: {
        priv.initialized = true
        refreshActiveProfiles()
    }
}
