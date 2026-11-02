pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs

Singleton {
    id: root

    // The viewer owns demand; SystemStats schedules the occasional read.
    property bool active: false
    readonly property var overall: ({ value: root._overallValue })
    readonly property bool available: root._available

    property real _overallValue: 0
    property bool _available: false

    onActiveChanged: {
        if (!root.active) {
            reader.running = false
            root._available = false
            root._overallValue = 0
        }
    }

    Process {
        id: reader
        command: ["df", "-B1", "--output=used,avail", "--", Settings.storageUsagePath]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector { id: usageOutput }
        stderr: StdioCollector { id: usageError }

        onExited: exitCode => {
            if (!root.active)
                return

            root._available = exitCode === 0 && root.publish(usageOutput.text)
            if (!root._available) {
                root._overallValue = 0
                console.warn("Storage:", usageError.text.trim()
                    || "Could not read filesystem usage for " + Settings.storageUsagePath)
            }
        }
    }

    // ────── Helper Functions ──────
    function update(): void {
        if (root.active && !reader.running)
            reader.running = true
    }

    function publish(output: string): bool {
        const lines = output.trim().split("\n")
        if (lines.length !== 2)
            return false

        const fields = lines[1].trim().split(/\s+/)
        if (fields.length !== 2)
            return false

        const usedBytes = Number(fields[0])
        const availableBytes = Number(fields[1])
        if (!Number.isFinite(usedBytes) || !Number.isFinite(availableBytes)
            || usedBytes < 0 || usedBytes + availableBytes <= 0)
            return false

        // Match df's percentage: reserved blocks are unavailable to the user.
        root._overallValue = Math.max(0, Math.min(100,
            usedBytes / (usedBytes + availableBytes) * 100))
        return true
    }
}
