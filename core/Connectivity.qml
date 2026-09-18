pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

import qs

//
// Wi-Fi and Bluetooth.
//
// Both are Quickshell services already speaking to NetworkManager and BlueZ
// over D-Bus, so there is nothing to poll and nothing to shell out to: the
// toggles are plain property writes, and the state that drives the glyphs
// comes back on its own.
//
// The two live in one singleton because they are one cluster on the bar and
// neither is big enough to earn a file — and because a core/Bluetooth.qml
// would shadow the service singleton of the same name.
//
Singleton {
    id: root

    // ══════════════════════════════════════════════════════════════════════
    //  Wi-Fi
    // ══════════════════════════════════════════════════════════════════════

    // ────── Public API ──────
    readonly property bool wifiEnabled: Networking.wifiEnabled

    // A hardware kill switch cannot be undone from software, so the toggle
    // refuses rather than leaving the glyph lying about what it did.
    readonly property bool wifiAvailable: Networking.wifiHardwareEnabled

    readonly property bool wifiConnected:
        root.wifiDevice !== null && root.wifiDevice.connected

    // Percent, because the thresholds and every other reading in the shell are
    // percentages — the service reports signal strength as a 0..1 real, which
    // an int property would silently floor to nothing.
    readonly property int wifiStrength: {
        if (!root.wifiConnected)
            return 0

        const networks = root.wifiDevice.networks.values

        for (let i = 0; i < networks.length; i++) {
            if (networks[i].connected)
                return Math.round(networks[i].signalStrength * 100)
        }

        return 0
    }

    readonly property string wifiIcon: {
        if (!root.wifiEnabled)
            return Settings.networkWifiOffIcon

        // Index 0 is the empty-bars glyph: radio up, nothing associated.
        if (!root.wifiConnected)
            return Settings.networkWiFiOnIcon[0]

        const level = resolveLevelIndex(
            root.wifiStrength, Settings.wifiSignalThresholds)

        return Settings.networkWiFiOnIcon[
            Math.min(level + 1, Settings.networkWiFiOnIcon.length - 1)]
    }

    // ────── Actions ──────
    function toggleWifi() {
        if (!root.wifiAvailable)
            return

        Networking.wifiEnabled = !Networking.wifiEnabled
    }

    // ────── Internals ──────
    readonly property var wifiDevice: {
        const devices = Networking.devices.values

        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i]
        }

        return null
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Bluetooth
    // ══════════════════════════════════════════════════════════════════════

    // ────── Public API ──────
    // Null on a machine with no controller, which reads as off throughout.
    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool bluetoothAvailable: root.adapter !== null
    readonly property bool bluetoothEnabled:
        root.bluetoothAvailable && root.adapter.enabled

    readonly property bool bluetoothConnected: {
        if (!root.bluetoothEnabled)
            return false

        const devices = Bluetooth.devices.values

        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                return true
        }

        return false
    }

    readonly property string bluetoothIcon: {
        if (!root.bluetoothEnabled)
            return Settings.bluetoothOffIcon

        return root.bluetoothConnected
            ? Settings.bluetoothConnectedIcon
            : Settings.bluetoothOnIcon
    }

    // ────── Actions ──────
    function toggleBluetooth() {
        if (!root.bluetoothAvailable)
            return

        root.adapter.enabled = !root.adapter.enabled
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Shared
    // ══════════════════════════════════════════════════════════════════════

    // Highest threshold at or below the value, as an index into the list.
    function resolveLevelIndex(value, thresholds) {
        let index = 0

        for (let i = 0; i < thresholds.length; i++) {
            if (value >= thresholds[i].threshold)
                index = i
        }

        return index
    }
}
