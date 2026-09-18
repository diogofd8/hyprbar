pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs

Singleton {
    id: root

    readonly property var overall: ({
        value: _overallValue,
        state: _overallState
    })

    // Absolute figures, in bytes. The percentage cannot be turned back into
    // these without the total, so both are published; the reverse is a
    // division. Units are in the names on purpose — /proc/meminfo reports kB.
    readonly property real usedBytes: _usedBytes
    readonly property real availableBytes: _availableBytes
    readonly property real totalBytes: _totalBytes

    property real _overallValue: 0
    property string _overallState: "low"

    property real _usedBytes: 0
    property real _availableBytes: 0
    property real _totalBytes: 0

    FileView {
        id: meminfoFile

        path: "/proc/meminfo"

        // Only `loaded`. A single reload() also emits `textChanged`, and
        // handling both would run process() twice per poll — see CpuStress.
        onLoaded: root.process()
    }

    function update() {
        meminfoFile.reload()
    }

    function process() {
        const text = meminfoFile.text()

        if (!text)
            return

        const fields = {}

        for (const line of text.split("\n")) {
            const match = /^(\w+):\s+(\d+) kB$/.exec(line.trim())

            if (match)
                fields[match[1]] = Number(match[2]) * 1024
        }

        const total = fields.MemTotal

        if (!total)
            return

        // MemAvailable is the kernel's own estimate of what a new allocation
        // could claim without swapping — it discounts reclaimable cache, which
        // MemFree does not. This is what `free` and waybar both report against,
        // so the displayed number stays consistent with the old bar.
        const available = fields.MemAvailable !== undefined
            ? fields.MemAvailable
            : (fields.MemFree ?? 0)
                + (fields.Buffers ?? 0)
                + (fields.Cached ?? 0)

        root._totalBytes = total
        root._availableBytes = available
        root._usedBytes = total - available

        root._overallValue = (root._usedBytes / total) * 100
        root._overallState = resolveState(
            root._overallValue,
            Settings.ramStressThresholds
        )

        // console.log(
        //     "RAM:",
        //     root._overallValue.toFixed(1) + "%",
        //     root._overallState,
        //     "|",
        //     (root._usedBytes / (1024 * 1024 * 1024)).toFixed(2) + " GiB used /",
        //     (root._totalBytes / (1024 * 1024 * 1024)).toFixed(2) + " GiB total |",
        //     (root._availableBytes / (1024 * 1024 * 1024)).toFixed(2) + " GiB available"
        // )
    }

    function resolveState(value, thresholds) {
        let state = "low"

        for (const entry of thresholds) {
            if (value >= entry.threshold)
                state = entry.state
            else
                break
        }

        return state
    }
}
