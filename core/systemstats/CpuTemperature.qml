pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

import qs

Singleton {
    id: root

    readonly property var overall: ({
        value: _overallValue,
        state: _overallState
    })

    readonly property var cores: _cores

    property real _overallValue: 0
    property string _overallState: "normal"

    property var _cores: []

    // hwmon indices are assigned in probe order and are not stable across
    // boots — x86_pkg_temp was thermal_zone6 when the waybar config was
    // written and is zone5 today. Both the chip and its individual sensors
    // are therefore discovered by name, never hardcoded.
    property string _hwmonPath: ""

    property string _packageFile: ""   // "tempN_input" for the whole package
    property var _coreOf: ({})         // "tempN_input" -> physical core id
    property var _inputFiles: []

    property var _readings: ({})       // "tempN_input" -> degrees celsius
    property int _pending: 0

    // ────── Discovery: locate the CPU temperature chip ──────

    FolderListModel {
        id: hwmonDirs

        folder: "file:///sys/class/hwmon"
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
    }

    Instantiator {
        model: hwmonDirs

        delegate: FileView {
            required property string fileName

            path: "/sys/class/hwmon/" + fileName + "/name"

            onLoaded: {
                const name = text().trim()

                if (name === "coretemp" || name === "k10temp")
                    root._hwmonPath = "/sys/class/hwmon/" + fileName
            }
        }
    }

    // ────── Discovery: map that chip's sensors to package / cores ──────

    FolderListModel {
        id: labelFiles

        folder: root._hwmonPath ? "file://" + root._hwmonPath : ""
        showDirs: false
        showFiles: true
        showDotAndDotDot: false
        nameFilters: ["temp*_label"]
    }

    Instantiator {
        model: labelFiles

        delegate: FileView {
            required property string fileName

            path: root._hwmonPath + "/" + fileName

            onLoaded: root.registerSensor(fileName, text().trim())
        }
    }

    // ────── Polling ──────

    Instantiator {
        id: inputs

        model: root._inputFiles

        delegate: FileView {
            required property var modelData

            path: root._hwmonPath + "/" + modelData

            onLoaded: {
                root._readings[modelData] = Number(text().trim()) / 1000
                root.settle()
            }

            onLoadFailed: root.settle()
        }
    }

    function update() {
        if (inputs.count === 0)
            return

        root._pending = inputs.count

        for (let i = 0; i < inputs.count; i++)
            inputs.objectAt(i).reload()
    }

    function registerSensor(labelFile, label) {
        const inputFile =
            labelFile.substring(0, labelFile.length - "_label".length)
            + "_input"

        // Intel exposes "Package id 0" + "Core N"; AMD exposes "Tctl"/"Tdie"
        // + "Tccd N". The AMD spelling is unverified on this machine.
        if (/^Package id \d+$/.test(label) || label === "Tctl" || label === "Tdie") {
            root._packageFile = inputFile
        } else {
            const match = /^(?:Core|Tccd) ?(\d+)$/.exec(label)

            if (!match)
                return

            root._coreOf[inputFile] = Number(match[1])
        }

        root._inputFiles = root._inputFiles.concat([inputFile])

        Qt.callLater(root.update)
    }

    function settle() {
        if (root._pending > 0 && --root._pending === 0)
            root.publish()
    }

    function publish() {
        const readings = root._readings

        // Core ids can be sparse (a CPU may report Core 0, 1, 4, 5), so sort
        // by id and emit a dense array rather than indexing by id directly.
        const found = []

        for (const file in root._coreOf) {
            if (readings[file] !== undefined)
                found.push({id: root._coreOf[file], value: readings[file]})
        }

        found.sort((a, b) => a.id - b.id)

        root._cores = found.map(core => makeReading(core.value))

        // Chips without a package sensor fall back to the hottest core, which
        // is what a package sensor reports anyway.
        const packageValue =
            readings[root._packageFile] !== undefined
                ? readings[root._packageFile]
                : found.reduce((hottest, core) =>
                    Math.max(hottest, core.value), undefined)

        if (packageValue === undefined)
            return

        const overall = makeReading(packageValue)

        root._overallValue = overall.value
        root._overallState = overall.state

        // console.log(
        //     "TEMP:",
        //     root._overallValue.toFixed(1) + "°C",
        //     root._overallState,
        //     "| Cores:",
        //     root._cores.map(core =>
        //         core.value.toFixed(1) + "°C (" + core.state + ")"
        //     ).join(" | ")
        // )
    }

    function makeReading(celsius) {
        return {
            value: celsius,
            state: resolveState(celsius, Settings.cpuTempThresholds)
        }
    }

    function resolveState(value, thresholds) {
        let state = "normal"

        for (const entry of thresholds) {
            if (value >= entry.threshold)
                state = entry.state
            else
                break
        }

        return state
    }
}
