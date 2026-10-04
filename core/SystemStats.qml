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

    // Per-thread usage and per-core temperatures are only worked out while
    // something shows them. The bar needs the overall values alone. Set by
    // the system-info dropdown, like the other services' discoveryActive.
    property bool detailActive: false

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

    Component.onCompleted: root.update()

    function update() {
        cpuStress.update()
        cpuTemperature.update()
        ramStress.update()
    }
}
