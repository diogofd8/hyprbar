pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.core as Core

Singleton {
    id: root

    readonly property string configRoot: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/oxidye"
    readonly property string path: configRoot + "/applied.json"
    readonly property bool available: snapshot !== null
    readonly property string mode: snapshot ? snapshot.mode : ""
    readonly property string source: snapshot ? snapshot.source : ""
    readonly property string image: snapshot ? snapshot.image || "" : ""
    readonly property string accentSeed: snapshot ? snapshot.seed : ""
    // Fixed and image themes have independent seeds. An applied fixed seed wins
    // over the source file, which Oxidye writes before committing applied.json.
    readonly property string fixedSeed: source === "fixed" ? accentSeed : storedFixedSeed
    readonly property string lastError: appliedError || configError || fixedError
    readonly property var roles: ["window_bg", "surface_low", "surface", "surface_high", "surface_highest", "scrollbar", "accent_bg"]
    property var snapshot: null
    property var pendingApplied: null
    property string storedFixedSeed: ""
    property string fixedAccentPath: ""
    property string appliedError: ""
    property string configError: ""
    property string fixedError: ""
    property bool appliedMissing: false

    function color(role: string, fallback: color): color {
        return snapshot && snapshot.colors[role] ? snapshot.colors[role] : fallback
    }
    function seedColor(fallback: color): color {
        const seed = source === "fixed" && available ? Core.Oklch.parse(accentSeed) : null
        return seed ? Core.Oklch.displayColor(seed.lightness, seed.chroma, seed.hue) : fallback
    }
    function refresh(): void { appliedFile.reload() }

    function acceptConfig(contents: string): void {
        try {
            const config = JSON.parse(contents)
            if (config.version !== 1 || typeof config.accents !== "string" || !config.accents
                || config.accents.startsWith("/") || config.accents.split("/").some(part => !part || part === "." || part === ".."))
                throw new Error("invalid configured accent path")
            fixedAccentPath = configRoot + "/" + config.accents
            configError = ""
            // Resolve the initial source before the picker is constructed.
            accentFile.text()
        } catch (error) { configError = "Could not load Oxidye configuration: " + error }
    }
    function acceptFixed(contents: string): void {
        try {
            const data = JSON.parse(contents)
            const seed = Core.Oklch.parse(data.seed)
            if (data.version !== 1 || !seed) throw new Error("invalid fixed accent seed")
            storedFixedSeed = Core.Oklch.format(seed, seed.hue)
            fixedError = ""
        } catch (error) { fixedError = "Could not load Oxidye accent: " + error }
    }
    function acceptApplied(contents: string): void {
        try {
            const data = JSON.parse(contents)
            const seed = Core.Oklch.parse(data.seed)
            if (data.version !== 1 || !["dark", "light"].includes(data.mode)
                || !["fixed", "matugen"].includes(data.source) || !seed)
                throw new Error("invalid applied theme metadata")
            // A first installation can create the directory between the two
            // initial reads. Its commit is also a chance to recover that config.
            if (configError) configFile.reload()
            pendingApplied = {mode: data.mode, source: data.source, seed: Core.Oklch.format(seed, seed.hue), image: typeof data.image === "string" ? data.image : ""}
            if (data.source === "fixed") {
                snapshot = {mode: data.mode, source: data.source, seed: pendingApplied.seed, colors: {}}
                appliedError = ""
            } else {
                // applied.json is Oxidye's commit marker. Read its report only
                // after that publication, not while toolkit files are staged.
                renderedFile.reload()
                renderedFile.text()
            }
        } catch (error) {
            pendingApplied = null
            appliedError = "Could not load Oxidye theme: " + error
        }
    }
    function acceptRendered(contents: string): void {
        if (!pendingApplied || pendingApplied.source !== "matugen") return
        try {
            const data = JSON.parse(contents)
            const seed = Core.Oklch.parse(data.seed)
            if (data.version !== 1 || data.mode !== pendingApplied.mode || !seed
                || Core.Oklch.format(seed, seed.hue) !== pendingApplied.seed || !data.colours)
                throw new Error("rendered palette does not match the applied theme")
            const colors = {}
            for (const role of roles) {
                const value = data.colours[role]
                if (!value || !Array.isArray(value.rgb) || value.rgb.length !== 3
                    || !value.rgb.every(channel => Number.isInteger(channel) && channel >= 0 && channel <= 255)
                    || !Number.isFinite(value.alpha) || value.alpha < 0 || value.alpha > 1)
                    throw new Error("invalid or missing colour: " + role)
                colors[role] = Qt.rgba(value.rgb[0] / 255, value.rgb[1] / 255, value.rgb[2] / 255, value.alpha)
            }
            snapshot = {mode: pendingApplied.mode, source: "matugen", seed: pendingApplied.seed, image: pendingApplied.image, colors: colors}
            appliedError = ""
        } catch (error) { appliedError = "Could not load Oxidye Matugen palette: " + error }
    }

    FileView {
        id: configFile
        path: root.configRoot + "/config.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.acceptConfig(text())
        onFileChanged: reload()
        onLoadFailed: error => root.configError = "Could not read Oxidye configuration: " + error
    }
    FileView {
        id: accentFile
        path: root.fixedAccentPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.acceptFixed(text())
        onFileChanged: reload()
        onLoadFailed: error => { if (root.fixedAccentPath) root.fixedError = "Could not read Oxidye accent: " + error }
    }
    FileView {
        id: appliedFile
        path: root.path
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: { root.appliedMissing = false; root.acceptApplied(text()) }
        onFileChanged: reload()
        onLoadFailed: error => {
            root.pendingApplied = null
            root.appliedMissing = error === FileViewError.FileNotFound
            root.appliedError = "Could not read applied Oxidye theme: " + error
        }
    }
    FileView {
        id: renderedFile
        path: root.pendingApplied?.source === "matugen" ? root.configRoot + "/matugen/gtk/applied.json" : ""
        blockLoading: true
        // Watch only to recover a missing/malformed report. Normal updates are
        // loaded through the commit marker, so colours and mode publish together.
        watchChanges: root.appliedError !== "" && root.pendingApplied?.source === "matugen"
        printErrors: false
        onLoaded: root.acceptRendered(text())
        onFileChanged: reload()
        onLoadFailed: error => {
            if (root.pendingApplied?.source === "matugen") root.appliedError = "Could not read Oxidye Matugen palette: " + error
        }
    }
    FileView {
        path: root.appliedMissing ? root.configRoot.slice(0, root.configRoot.lastIndexOf("/")) : ""
        watchChanges: true
        printErrors: false
        onFileChanged: { configFile.reload(); appliedFile.reload() }
    }
    Component.onCompleted: { configFile.text(); appliedFile.text() }
}
