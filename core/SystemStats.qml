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
