pragma Singleton

import QtQuick
import Quickshell

import qs
import "./systemstats"

Singleton {
    id: root

    // ────── Public Handlers ──────
    readonly property var cpuStress: CpuStress
    readonly property var cpuTemperature: CpuTemperature
    readonly property var ramStress: RamStress
    readonly property var igpuStress: IgpuStress
    readonly property var storageUsage: StorageUsage

    // Per-thread usage and per-core temperatures are only worked out while
    // something shows them. The bar needs the overall values alone. Set by
    // the system-info dropdown, like the other services' discoveryActive.
    property bool detailActive: false

    // Seed per-thread counters on open, so the next normal tick can report
    // utilization. Let the reader bindings below update before sampling.
    onDetailActiveChanged: {
        if (root.detailActive)
            Qt.callLater(root.update)
    }

    Binding {
        target: CpuStress
        property: "detailActive"
        value: root.detailActive
    }

    Binding {
        target: CpuTemperature
        property: "detailActive"
        value: root.detailActive
    }

    Timer {
        interval: Settings.systemStatsPollingIntervalMs
        running: true
        repeat: true

        onTriggered: root.update()
    }

    Timer {
        interval: Settings.storageUsagePollingIntervalMs
        running: root.storageUsage.active
        repeat: true
        triggeredOnStart: true

        onTriggered: root.storageUsage.update()
    }

    Component.onCompleted: root.update()

    function update() {
        cpuStress.update()
        cpuTemperature.update()
        ramStress.update()
    }
}
