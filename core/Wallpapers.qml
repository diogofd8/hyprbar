pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

import qs.widgets.thememanager as ThemeUI

Singleton {
    id: root

    property bool active: false
    property string monitorName: ""
    readonly property var model: catalog.item
    readonly property int count: model ? model.count : 0
    readonly property bool ready: model !== null && model.status === FolderListModel.Ready
    readonly property bool refreshing: query.running
    readonly property string currentWallpaper: wallpaperFor(monitorName)
    property var activeWallpapers: ({})
    property bool refreshComplete: false
    property bool available: false
    property string lastError: ""

    signal refreshed()
    signal applyFinished(bool success, string error)

    function normalizePath(path: string): string {
        if (path.startsWith("file://"))
            path = decodeURIComponent(path.slice(7))
        const parts = []
        for (const part of path.split("/")) {
            if (!part || part === ".") continue
            if (part === "..") parts.pop()
            else parts.push(part)
        }
        return path.startsWith("/") ? "/" + parts.join("/") : ""
    }

    function fileAt(index: int): string {
        return model && index >= 0 && index < count ? model.get(index, "filePath") : ""
    }

    function wallpaperFor(monitor: string): string {
        return activeWallpapers[monitor] || ""
    }

    function refresh(): void {
        if (query.running) return
        refreshComplete = false
        query.launched = false
        query.exec(["hyprctl", "hyprpaper", "listactive"])
    }

    function finishQuery(error: string): void {
        lastError = error
        available = error.length === 0
        refreshComplete = true
        refreshed()
    }

    function apply(imagePath: string, monitor: string): bool {
        if (setter.running) return false
        setter.launched = false
        setter.exec(["hyprctl", "hyprpaper", "wallpaper", monitor + "," + imagePath + ",cover"])
        return true
    }

    onActiveChanged: {
        if (active) refresh()
    }
    onMonitorNameChanged: {
        if (active && monitorName.length > 0) refresh()
    }

    // Unload the directory model and its filesystem watcher with the page.
    Loader {
        id: catalog
        active: root.active
        sourceComponent: Component {
            FolderListModel {
                folder: "file://" + ThemeUI.Configuration.wallpaperDirectory.split("/").map(part => encodeURIComponent(part)).join("/")
                nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.avif", "*.jxl"]
                caseSensitive: false
                showDirs: false
                showHidden: false
                showOnlyReadable: true
                sortField: FolderListModel.Name
                sortCaseSensitive: false
            }
        }
    }

    Process {
        id: query
        property bool launched: false
        stdout: StdioCollector { id: queryOutput }
        stderr: StdioCollector { id: queryError }
        onStarted: launched = true
        onExited: (code, status) => {
            if (code !== 0 || status !== 0) {
                root.finishQuery(queryError.text.trim() || queryOutput.text.trim() || "Could not query Hyprpaper.")
                return
            }
            const wallpapers = {}
            for (const line of queryOutput.text.trim().split("\n")) {
                const separator = line.indexOf(": ")
                if (separator > 0)
                    wallpapers[line.slice(0, separator)] = root.normalizePath(line.slice(separator + 2))
            }
            root.activeWallpapers = wallpapers
            root.finishQuery(Object.keys(wallpapers).length ? "" : "Hyprpaper did not report any active wallpapers.")
        }
        onRunningChanged: {
            if (!running && !launched) Qt.callLater(() => {
                if (!query.running && !query.launched) root.finishQuery("Could not start hyprctl to query Hyprpaper.")
            })
        }
    }

    Process {
        id: setter
        property bool launched: false
        stdout: StdioCollector { id: setterOutput }
        stderr: StdioCollector { id: setterError }
        onStarted: launched = true
        onExited: (code, status) => {
            const error = code !== 0 || status !== 0
                ? setterError.text.trim() || setterOutput.text.trim() || "Hyprpaper failed (exit " + code + ")." : ""
            root.refresh()
            root.applyFinished(error.length === 0, error)
        }
        onRunningChanged: {
            if (!running && !launched) Qt.callLater(() => {
                if (!setter.running && !setter.launched) root.applyFinished(false, "Could not start hyprctl.")
            })
        }
    }
}
