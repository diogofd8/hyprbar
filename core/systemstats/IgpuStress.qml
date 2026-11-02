pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs

Singleton {
    id: root

    // The viewer owns demand; the bar does not need a GPU sampling process.
    property bool active: false

    readonly property var overall: ({ value: root._overallValue })
    readonly property bool available: root._available

    property real _overallValue: 0
    property bool _available: false
    property var _busyColumns: []
    property int _columnCount: 0
    property bool _skipFirstSample: true

    Process {
        id: sampler

        // Physical engines (-p), rather than class averages, match btop's
        // busiest-engine percentage. CSV avoids parsing per-client JSON.
        command: ["intel_gpu_top", "-c", "-p", "-s", String(Settings.systemStatsPollingIntervalMs)]
        running: root.active

        onStarted: root.reset()
        onRunningChanged: {
            if (!sampler.running)
                root.reset()
        }
        onExited: exitCode => {
            if (root.active && exitCode !== 0)
                console.warn("iGPU:", samplerError.text.trim() || "intel_gpu_top exited with code " + exitCode)
        }

        stdout: SplitParser {
            onRead: data => root.readSample(data)
        }
        stderr: StdioCollector {
            id: samplerError
        }
    }

    // ────── Helper Functions ──────
    function reset(): void {
        root._available = false
        root._overallValue = 0
        root._busyColumns = []
        root._columnCount = 0
        root._skipFirstSample = true
    }

    function readSample(data: string): void {
        if (!root.active || !sampler.running || !data.trim())
            return

        const fields = data.trim().split(",").map(field => field.trim())
        const busyColumns = []
        for (let index = 0; index < fields.length; ++index) {
            if (/^(RCS|BCS|VCS|VECS|CCS|UNKN)\/\d+ %$/.test(fields[index]))
                busyColumns.push(index)
        }

        if (busyColumns.length > 0) {
            root._busyColumns = busyColumns
            root._columnCount = fields.length
            root._skipFirstSample = true
            return
        }

        if (root._busyColumns.length === 0 || fields.length !== root._columnCount)
            return

        let busiest = 0
        for (const index of root._busyColumns) {
            const value = Number(fields[index])
            if (!fields[index] || !Number.isFinite(value))
                return
            busiest = Math.max(busiest, value)
        }

        // intel_gpu_top emits an immediate startup sample before a full
        // interval has elapsed. Wait for its first measured interval.
        if (root._skipFirstSample) {
            root._skipFirstSample = false
            return
        }

        root._overallValue = Math.max(0, Math.min(100, busiest))
        root._available = true
    }
}
