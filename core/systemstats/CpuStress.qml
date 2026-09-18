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

    readonly property var threads: _threads

    property real _overallValue: 0
    property string _overallState: "idle"

    property var _threads: []
    property var _previousCounters: ({})

    FileView {
        id: statFile

        path: "/proc/stat"

        // Only `loaded`. A single reload() also emits `textChanged`, and
        // handling both would run process() twice against the same snapshot;
        // the second pass would see a zero delta and flatten every reading.
        onLoaded: root.process()
    }

    function update() {
        statFile.reload()
    }

    function process() {
        const text = statFile.text()

        if (!text)
            return

        const lines = text.split("\n")
        const currentCounters = {}

        for (const line of lines) {
            if (!line.startsWith("cpu"))
                continue

            const fields = line.trim().split(/\s+/)
            const name = fields[0]

            if (name !== "cpu" && !/^cpu\d+$/.test(name))
                continue

            if (fields.length < 5)
                continue

            currentCounters[name] = parseCounters(fields)
        }

        const previousCounters = root._previousCounters

        // A re-read that did not advance the aggregate counter is a stale
        // snapshot, not an idle CPU. Keep the last reading instead of
        // reporting a bogus 0%.
        if (previousCounters["cpu"] !== undefined
            && total(currentCounters["cpu"]) <= total(previousCounters["cpu"]))
            return

        root._previousCounters = currentCounters

        if (previousCounters["cpu"] === undefined)
            return

        const threadValues = []

        for (const name in currentCounters) {
            if (previousCounters[name] === undefined)
                continue

            const usage = calculateUsage(
                previousCounters[name],
                currentCounters[name]
            )

            const result = {
                value: usage,
                state: resolveState(
                    usage,
                    Settings.cpuStressThresholds
                )
            }

            if (name === "cpu") {
                root._overallValue = result.value
                root._overallState = result.state
            } else {
                threadValues[Number(name.substring(3))] = result
            }
        }

        root._threads = threadValues

        // console.log(
        //     "CPU:",
        //     root._overallValue.toFixed(1) + "%",
        //     root._overallState,
        //     "| Threads:",
        //     threadValues.map(thread =>
        //         thread
        //             ? thread.value.toFixed(1) + "% (" + thread.state + ")"
        //             : "N/A"
        //     ).join(" | ")
        // )
    }

    function parseCounters(fields) {
        return {
            user: Number(fields[1]),
            nice: Number(fields[2]),
            system: Number(fields[3]),
            idle: Number(fields[4]),
            iowait: Number(fields[5] ?? 0),
            irq: Number(fields[6] ?? 0),
            softirq: Number(fields[7] ?? 0),
            steal: Number(fields[8] ?? 0)
        }
    }

    function total(counters) {
        return counters.user
            + counters.nice
            + counters.system
            + counters.idle
            + counters.iowait
            + counters.irq
            + counters.softirq
            + counters.steal
    }

    function calculateUsage(previous, current) {
        const idleDelta =
            (current.idle + current.iowait)
            - (previous.idle + previous.iowait)

        const totalDelta = total(current) - total(previous)

        if (totalDelta <= 0)
            return 0

        return Math.max(
            0,
            Math.min(
                100,
                (1 - idleDelta / totalDelta) * 100
            )
        )
    }

    function resolveState(value, thresholds) {
        let state = "idle"

        for (const entry of thresholds) {
            if (value >= entry.threshold)
                state = entry.state
            else
                break
        }

        return state
    }
}
