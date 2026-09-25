pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth as BlueZ

import qs

// BlueZ-backed adapter and device state, published as three mutually exclusive
// device models. The bar only reads state; the popup owns discovery demand.
Singleton {
    id: root

    // ────── Adapter ──────
    // Null on a machine with no controller, which reads as off throughout.
    readonly property var adapter: BlueZ.Bluetooth.defaultAdapter

    readonly property bool bluetoothAvailable: root.adapter !== null
    readonly property bool bluetoothEnabled: root.bluetoothAvailable && root.adapter.enabled
    readonly property bool bluetoothBlocked: isBluetoothBlocked()
    readonly property bool bluetoothBusy: isBluetoothBusy()

    function isBluetoothBlocked() {
        if (!root.bluetoothAvailable)
            return false;

        switch (root.adapter.state) {
            case BlueZ.BluetoothAdapterState.Blocked: return true;
            default: return false;
        }
    }

    function isBluetoothBusy() {
        if (!root.bluetoothAvailable)
            return false;

        switch (root.adapter.state) {
            case BlueZ.BluetoothAdapterState.Enabling: return true;
            case BlueZ.BluetoothAdapterState.Disabling: return true;
            default: return false;
        }
    }

    // Devices are scoped to the default adapter. A powered-off adapter reports
    // none, which is what collapses every section while Bluetooth is off.
    readonly property var deviceList: root.bluetoothEnabled ? root.adapter.devices.values : []

    readonly property bool bluetoothConnected: {
        const devices = root.deviceList
        for (let i = 0; i < devices.length; ++i) {
            if (devices[i].connected) return true
        }
        return false
    }

    readonly property string bluetoothIcon: {
        if (!root.bluetoothEnabled)
            return Settings.bluetoothOffIcon

        return root.bluetoothConnected ? Settings.bluetoothConnectedIcon : Settings.bluetoothOnIcon
    }

    // Shown in place of the device sections when there is nothing to act on.
    readonly property string statusMessage: {
        if (!root.bluetoothAvailable)
            return "No Bluetooth adapter found"

        if (root.bluetoothBlocked)
            return "Bluetooth is blocked by hardware"

        if (!root.bluetoothEnabled)
            return "Turn on Bluetooth to see devices"

        return ""
    }

    // Pairing is the one operation that hands a prompt to another process.
    // BlueZ routes passkey, PIN and authorization callbacks to the agent
    // belonging to the connection that called Pair(); Quickshell can register
    // none, so they go to the system agent, whose dialog steals focus. The
    // popup has to outlive that rather than treating it as a dismissal.
    readonly property bool pairingInFlight: priv.operationMode === "pair"

    function setEnabled(enabled) {
        if (!root.bluetoothAvailable || root.bluetoothBusy)
            return

        if (root.adapter.enabled === enabled)
            return

        root.adapter.enabled = enabled
    }

    function toggleBluetooth() {
        root.setEnabled(!root.bluetoothEnabled)
    }

    onBluetoothEnabledChanged: {
        if (root.bluetoothEnabled)
            return

        // Turning the adapter off invalidates everything below it.
        root.stopDiscovery()
        root.clearScanResults()
        priv.entryErrors = ({})
        priv.scanError = ""

        if (priv.operationAddress)
            root.finishOperation("Bluetooth was turned off.")
    }

    // ────── Discovery ──────
    // The popup owns discovery demand. No scans are requested by the bar.
    property bool discoveryActive: false
    // Whether the user asked for a scan, as opposed to the popup merely being
    // open. Discovery only runs when both are true.
    property bool scanRequested: false

    readonly property bool scanning: root.bluetoothEnabled && root.adapter.discovering
    // BlueZ refuses StartDiscovery while the controller is tied up with a
    // pending link ("br-connection-busy"), and says so by simply not starting.
    readonly property string scanErrorMessage: priv.scanError
    // Whether a scan has run this session, which is what keeps the scan
    // section on screen to report that it turned nothing up.
    property bool scanPerformed: false

    function startDiscovery() {
        if (!root.bluetoothEnabled)
            return

        priv.scanError = ""
        root.scanRequested = true
        root.scanPerformed = true
        root.adapter.discovering = true
        scanStartTimeout.restart()
    }

    function stopDiscovery() {
        scanStartTimeout.stop()
        priv.scanError = ""
        root.scanRequested = false
        priv.discoverySuspended = false

        if (root.bluetoothAvailable && root.adapter.discovering)
            root.adapter.discovering = false
    }

    // A running scan starves link establishment: the same connect that takes
    // two seconds with the radio idle times out after thirty while discovery
    // is on. Operations therefore borrow the radio and hand it back.
    function suspendDiscovery() {
        if (!root.scanning)
            return

        priv.discoverySuspended = true
        root.adapter.discovering = false
    }

    function resumeDiscovery() {
        if (!priv.discoverySuspended)
            return

        priv.discoverySuspended = false

        if (root.scanRequested && root.discoveryActive && root.bluetoothEnabled)
            root.adapter.discovering = true
    }

    function toggleDiscovery() {
        if (root.scanRequested || root.scanning) {
            root.stopDiscovery()
            return;
        }

        root.startDiscovery()
    }

    onDiscoveryActiveChanged: {
        if (root.discoveryActive)
            return

        // Closing the popup ends the scan session: results and errors are
        // session state, so the next open starts clean.
        root.stopDiscovery()
        root.clearScanResults()
        priv.entryErrors = ({})
    }

    // BlueZ has no "discovered" flag, so the scan section is a session list of
    // unpaired addresses seen while discovery was running. It survives the scan
    // stopping and is dropped when the popup closes or the user clears it.
    function collectScanResults() {
        if (!root.scanning || !root.discoveryActive)
            return

        const seen = priv.scanSession.slice()
        let added = false
        for (const device of root.deviceList) {
            if (device.paired || device.bonded || device.connected)
                continue

            if (seen.indexOf(device.address) !== -1)
                continue

            seen.push(device.address)
            added = true
        }

        if (added)
            priv.scanSession = seen
    }

    function clearScanResults() {
        root.scanPerformed = false

        if (priv.scanSession.length > 0)
            priv.scanSession = []
    }

    // scanRequested is the user's intent and only they revoke it. Deriving it
    // from `scanning` instead races BlueZ's async stop acknowledgement and
    // silently cancels the scan whenever an operation borrows the radio.
    onScanningChanged: {
        if (!root.scanning)
            return

        scanStartTimeout.stop()
        priv.scanError = ""
        root.collectScanResults()
    }

    Timer {
        id: scanStartTimeout
        interval: 4000

        onTriggered: {
            if (root.scanning || !root.scanRequested)
                return

            // Nothing is scanning, so the button must stop offering to stop it.
            root.scanRequested = false
            root.scanPerformed = false
            priv.scanError = "Bluetooth is busy — the scan could not start."
        }
    }

    // Devices appear, disappear and change pairing state outside any operation
    // we started, so one signature drives both scan collection and removal.
    readonly property string deviceSignature:
        root.deviceList.map(device => device.address + ":" + (device.paired || device.bonded)).join("\n")

    onDeviceSignatureChanged: {
        if (priv.operationMode === "forget" && !root.findDevice(priv.operationAddress))
            root.finishOperation()

        root.collectScanResults()
    }

    // ────── Device models ──────
    readonly property var entrySnapshots: {
        const connected = []
        const paired = []
        const discovered = []

        for (const device of root.deviceList) {
            const state = root.deviceState(device)
            const row = root.makeEntry(device, state)

            // Mutually exclusive by design: a connected device is only ever in Connected, a remembered one only ever in Paired.
            // The test is the resolved state, never device.connected: BlueZ raises a transport partway through pairing, and a pairing
            // that later fails must never have claimed a section it did not earn.
            // Disconnecting keeps a remembered device from flickering into Paired mid-teardown, but an unpaired one has no such row to
            // protect: it goes straight back to the scan list rather than touching Connected on its way out.
            if (state === "Connected" || (state === "Disconnecting" && (device.paired || device.bonded)))
                connected.push(row)
            else if (device.paired || device.bonded)
                paired.push(row)
            else if (priv.scanSession.indexOf(device.address) !== -1)
                discovered.push(row)
        }

        const byName = (a, b) => a.name.localeCompare(b.name)
        connected.sort(byName)
        paired.sort(byName)
        // Discovery order, oldest first, so rows already on screen never move.
        discovered.sort((a, b) => priv.scanSession.indexOf(a.address) - priv.scanSession.indexOf(b.address))

        return {connected: connected, paired: paired, discovered: discovered}
    }

    readonly property var connectedDevices: connectedModel
    readonly property var pairedDevices: pairedModel
    readonly property var discoveredDevices: discoveredModel

    onEntrySnapshotsChanged: {
        syncModel(connectedModel, root.entrySnapshots.connected)
        syncModel(pairedModel, root.entrySnapshots.paired)
        syncModel(discoveredModel, root.entrySnapshots.discovered)
    }

    ListModel { id: connectedModel }
    ListModel { id: pairedModel }
    ListModel { id: discoveredModel }

    function deviceState(device) {
        if (priv.operationAddress === device.address) {
            switch (priv.operationMode) {
                case "pair": return "Pairing"
                case "forget": return "Removing"
                case "disconnect": return "Disconnecting"
                case "connect": return "Connecting"
            }
        }

        if (device.pairing) return "Pairing"

        // Deliberately no Connecting case. BlueZ goes on reporting it for
        // many seconds after Disconnect() aborts an attempt, which would leave
        // a cancelled row claiming to still be working; and an attempt this
        // widget did not start is not one it can narrate or cancel. Our own
        // connects are covered by the operation overlay above.
        switch (device.state) {
            case BlueZ.BluetoothDeviceState.Disconnecting: return "Disconnecting"
            case BlueZ.BluetoothDeviceState.Connected: return "Connected"
        }

        if (device.connected) return "Connected"
        return (device.paired || device.bonded) ? "Paired" : "Disconnected"
    }

    function makeEntry(device, state) {
        const address = device.address
        // One operation at a time: every other row goes quiet while it runs.
        const busy = priv.operationAddress !== ""
        const mine = priv.operationAddress === address
        const known = device.paired || device.bonded
        return {
            address: address,
            name: device.name || device.deviceName || address,
            icon: device.icon || "",
            state: state,
            paired: known,
            connected: device.connected,
            trusted: device.trusted,
            batteryAvailable: device.batteryAvailable,
            battery: device.batteryAvailable ? Math.round(device.battery * 100) : 0,
            errorMessage: priv.entryErrors[address] || "",
            canPair: !known && !busy && state === "Disconnected",
            canConnect: known && !busy && !device.connected,
            canDisconnect: !busy && device.connected && state === "Connected",
            canForget: !busy && (known || device.connected),
            canCancel: mine && (priv.operationMode === "pair" || priv.operationMode === "connect")
        }
    }

    function syncModel(model, entries) {
        const addresses = new Set(entries.map(entry => entry.address))
        for (let i = model.count - 1; i >= 0; --i) {
            if (!addresses.has(model.get(i).address))
                model.remove(i)
        }

        for (let i = 0; i < entries.length; ++i) {
            const row = entries[i]
            let existing = i
            while (existing < model.count && model.get(existing).address !== row.address)
                ++existing

            if (existing === model.count)
                model.insert(i, row)
            else {
                if (existing !== i)
                    model.move(existing, i, 1)
                for (const key of Object.keys(row)) {
                    if (model.get(i)[key] !== row[key])
                        model.setProperty(i, key, row[key])
                }
            }
        }
    }

    function findDevice(address) {
        const devices = root.deviceList
        for (let i = 0; i < devices.length; ++i) {
            if (devices[i].address === address)
                return devices[i]
        }

        return null
    }

    // ────── Errors ──────
    function setEntryError(address, message) {
        const errors = Object.assign({}, priv.entryErrors)
        if (message)
            errors[address] = message
        else
            delete errors[address]
        priv.entryErrors = errors
    }

    function clearEntryError(address) {
        root.setEntryError(address, "")
    }

    // ────── Operations ──────
    function beginOperation(address, device, mode, timeoutMs) {
        if (priv.operationAddress)
            return false

        root.clearEntryError(address)
        priv.operationAddress = address
        priv.operationMode = mode
        priv.operationDevice = device
        operationTimeout.interval = timeoutMs
        operationTimeout.restart()
        root.suspendDiscovery()
        return true
    }

    function finishOperation(error = "") {
        const address = priv.operationAddress
        operationTimeout.stop()
        pairSettle.stop()
        priv.operationAddress = ""
        priv.operationMode = ""
        priv.operationDevice = null

        if (address && error)
            root.setEntryError(address, error)

        root.resumeDiscovery()
    }

    // BlueZ only bonds, so trusting is chained on here. Connecting is left to
    // the user: the device lands in Paired with a connect button already on it,
    // and pairing is the half that needs a human at the other end.
    function pair(address) {
        const device = root.findDevice(address)
        if (!device || device.paired || device.bonded) return
        if (!root.beginOperation(address, device, "pair", 60000)) return
        device.pair()
    }

    function connect(address) {
        const device = root.findDevice(address)
        if (!device || device.connected) return
        if (!root.beginOperation(address, device, "connect", 30000)) return
        device.connect()
    }

    function disconnect(address) {
        const device = root.findDevice(address)
        if (!device || !device.connected) return
        if (!root.beginOperation(address, device, "disconnect", 15000)) return
        device.disconnect()
    }

    function forget(address) {
        const device = root.findDevice(address)
        if (!device) return
        if (!root.beginOperation(address, device, "forget", 15000)) return
        device.forget()
    }

    // A device that is merely switched off accepts no link, so Connect() sits
    // there until it times out. BlueZ has no abort-connect; Disconnect() is
    // what drops a pending link, which is how the row gets its escape hatch.
    function cancelOperation(address) {
        if (priv.operationAddress !== address) return
        const device = priv.operationDevice
        switch (priv.operationMode) {
            case "pair":
                if (device) device.cancelPair()
                root.failPairing()
                return
            case "connect":
                // Quickshell refuses Disconnect() on a device that has not linked
                // yet, so a pending attempt can only be abandoned locally: the row
                // is freed at once and the controller frees itself a few seconds
                // later. Calling it while a link exists still tears that link down.
                if (device && device.connected) device.disconnect()
                break
            default:
                return
        }
        root.finishOperation()
    }

    // A cancelled or failed pairing can leave BlueZ's transport up with no bond
    // behind it. Drop it, so the row falls back to the scan list instead of
    // claiming a connection the user never completed.
    function failPairing(message) {
        const device = priv.operationDevice
        if (device && !device.paired && !device.bonded && device.connected)
            device.disconnect()
        root.finishOperation(message)
    }

    function checkOperation() {
        const device = priv.operationDevice
        if (!device || !priv.operationAddress) return

        switch (priv.operationMode) {
            case "pair":
                if (device.paired || device.bonded) {
                    // Trust it so BlueZ lets it reconnect on its own later, then
                    // stop: the row now sits in Paired offering a connect button.
                    device.trusted = true
                    root.finishOperation()
                } else if (!device.pairing) {
                    // paired and pairing settle in an unspecified order, so give
                    // the failure a beat to be contradicted before reporting it.
                    pairSettle.restart()
                }
                break
            case "connect":
                if (device.connected) root.finishOperation()
                break
            case "disconnect":
                if (!device.connected
                        && device.state === BlueZ.BluetoothDeviceState.Disconnected)
                    root.finishOperation()
                break
        }
    }

    Connections {
        target: priv.operationDevice

        function onConnectedChanged() { root.checkOperation() }
        function onStateChanged() { root.checkOperation() }
        function onPairedChanged() { root.checkOperation() }
        function onBondedChanged() { root.checkOperation() }
        function onPairingChanged() { root.checkOperation() }
    }

    Timer {
        id: pairSettle
        interval: 250
        onTriggered: {
            const device = priv.operationDevice
            if (!device || priv.operationMode !== "pair") return
            if (device.paired || device.bonded) root.checkOperation()
            else if (!device.pairing)
                root.failPairing("Pairing failed or was rejected.")
        }
    }

    Timer {
        id: operationTimeout
        onTriggered: {
            switch (priv.operationMode) {
                case "pair":
                    root.failPairing("Pairing did not complete in time.")
                    break
                case "forget":
                    root.finishOperation("The device could not be removed.")
                    break
                case "disconnect":
                    root.finishOperation("Disconnecting did not complete in time.")
                    break
                default:
                    root.finishOperation("Connecting did not complete in time.")
            }
        }
    }

    function openSettings() { Actions.bluetoothManager() }

    QtObject {
        id: priv
        property bool discoverySuspended: false
        property var scanSession: []
        property var entryErrors: ({})
        property string scanError: ""
        property string operationAddress: ""
        property string operationMode: ""
        property var operationDevice: null
    }
}
