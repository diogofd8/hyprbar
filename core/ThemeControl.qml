pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.core as Core
import qs.widgets.thememanager as ThemeUI

Singleton {
    id: root

    readonly property bool canToggleMode: Core.SystemPalette.available
    readonly property bool canApplyAccent: Core.Oklch.parse(Core.SystemPalette.fixedSeed) !== null
    readonly property bool busy: phase !== "idle"
    readonly property var savedSpectra: {
        const result = []
        for (const seed of ThemeUI.Configuration.savedSpectra.concat(userSpectra)) {
            const normalized = root.normalizeSeed(seed)
            if (normalized && !result.includes(normalized)) result.push(normalized)
        }
        return result
    }
    property string phase: "idle"
    property string lastError: ""
    property string spectraError: ""
    property bool spectraWritable: false
    property var userSpectra: []
    property var pendingSpectra: []
    signal accentApplied(string seed)

    function normalizeSeed(seed): string {
        const parsed = Core.Oklch.parse(seed)
        return parsed ? Core.Oklch.format(parsed, parsed.hue) : ""
    }
    function toggleMode(): bool {
        if (busy) return false
        if (!canToggleMode) return reject("No valid applied Oxidye theme is available to toggle.")
        const mode = Core.SystemPalette.mode === "dark" ? "light" : "dark"
        return begin("mode", [ThemeUI.Configuration.oxidyeExecutable,
            Core.SystemPalette.source === "matugen" ? "matugen" : "theme", "--mode", mode, "--format", "json"])
    }
    function applyAccent(seed: string): bool {
        if (busy) return false
        const selected = normalizeSeed(seed)
        if (!canApplyAccent || !selected) return reject("No valid opaque OKLCH accent is available to apply.")
        if (Core.SystemPalette.source === "fixed" && selected === normalizeSeed(Core.SystemPalette.accentSeed)) return false
        return begin("accent", [ThemeUI.Configuration.oxidyeExecutable, "theme", "--accent", selected, "--format", "json"])
    }
    function saveSpectrum(seed: string): bool {
        if (busy) return false
        const normalized = normalizeSeed(seed)
        if (!normalized || !spectraWritable) return reject(spectraError || "Saved colours are not available yet.")
        if (savedSpectra.includes(normalized)) return false
        lastError = ""
        pendingSpectra = userSpectra.concat([normalized])
        phase = "spectra"
        spectraFile.setText(JSON.stringify({version: 1, seeds: pendingSpectra}, null, 2) + "\n")
        return true
    }
    function begin(operation: string, command): bool {
        lastError = ""
        phase = operation
        commandProcess.launched = false
        commandProcess.exec(command)
        return true
    }
    function reject(message: string): bool { lastError = message; return false }
    function finish(message: string): void { lastError = message; phase = "idle" }
    function loadSpectra(contents: string): void {
        try {
            const data = JSON.parse(contents)
            if (data.version !== 1 || !Array.isArray(data.seeds) || !data.seeds.every(seed => normalizeSeed(seed)))
                throw new Error("invalid spectrum collection")
            userSpectra = [...new Set(data.seeds.map(seed => normalizeSeed(seed)))]
            spectraError = ""
            spectraWritable = true
        } catch (error) { spectraError = "Could not load saved colours: " + error; spectraWritable = false }
    }
    FileView {
        id: spectraFile
        path: Quickshell.statePath("theme-spectra.json")
        atomicWrites: true
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.loadSpectra(text())
        onFileChanged: reload()
        onLoadFailed: error => {
            root.spectraWritable = error === FileViewError.FileNotFound
            root.spectraError = root.spectraWritable ? "" : "Could not read saved colours: " + error
        }
        onSaved: {
            if (root.phase !== "spectra") return
            root.userSpectra = root.pendingSpectra
            root.finish("")
        }
        onSaveFailed: error => { if (root.phase === "spectra") root.finish("Could not save colour: " + error) }
    }
    Component.onCompleted: spectraFile.text()

    Process {
        id: commandProcess
        property bool launched: false
        stdout: StdioCollector { id: commandOutput }
        stderr: StdioCollector { id: commandError }
        onStarted: launched = true
        onExited: (code, exitStatus) => {
            if (code !== 0 || exitStatus !== 0) {
                root.finish(commandError.text.trim() || "Oxidye failed (exit " + code + ").")
                return
            }
            try {
                const result = JSON.parse(commandOutput.text)
                const seed = root.normalizeSeed(result.seed)
                if (result.version !== 1 || !["dark", "light"].includes(result.mode)
                    || !["fixed", "matugen"].includes(result.source) || !seed)
                    throw new Error("invalid application result")
                const appliedAccent = root.phase === "accent"
                Core.SystemPalette.refresh()
                root.finish("")
                if (appliedAccent) root.accentApplied(seed)
            } catch (error) { root.finish("Could not read Oxidye result: " + error) }
        }
        // Quickshell 0.3 does not emit exited when an executable cannot start.
        onRunningChanged: {
            if (!running && !launched && root.busy && root.phase !== "spectra") {
                Qt.callLater(() => {
                    if (!commandProcess.running && !commandProcess.launched && root.busy && root.phase !== "spectra")
                        root.finish("Oxidye could not start. Check its configured executable path.")
                })
            }
        }
    }
}
