pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth as BlueZ

import qs

// Bluetooth state and actions, updated by BlueZ through Quickshell.
Singleton {
    id: root

    // ────── Public API ──────
    // Null on a machine with no controller, which reads as off throughout.
    readonly property var adapter: BlueZ.Bluetooth.defaultAdapter

    readonly property bool bluetoothAvailable: root.adapter !== null
    readonly property bool bluetoothEnabled:
        root.bluetoothAvailable && root.adapter.enabled

    readonly property bool bluetoothConnected: {
        if (!root.bluetoothEnabled)
            return false

        const devices = BlueZ.Bluetooth.devices.values

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
}
