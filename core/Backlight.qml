pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

import qs

Singleton {
    id: root

    // ────── Public API ──────
    readonly property bool available: deviceName !== "" && maxRaw > 0

    readonly property int value:
        available ? Math.round(targetRaw / maxRaw * 100) : 0

    readonly property int levelIndex:
        resolveLevelIndex(value, Settings.brightnessLevelThresholds)

    readonly property string level:
        Settings.brightnessLevelThresholds[levelIndex].state

    readonly property string icon:
        Settings.brightnessCtrlIcon[
            Math.min(levelIndex, Settings.brightnessCtrlIcon.length - 1)]

    // ────── Actions ──────
    function setBrightness(percent) {
        if (!available)
            return

        applyRaw(Math.round(percent / 100 * maxRaw))
    }

    // `steps` is a count, matching ChevronButton's scrolled(steps).
    function stepBrightness(steps) {
        if (!available)
            return

        // Stepping from targetRaw rather than from the hardware reading: a
        // fast scroll fires several steps before sysfs has caught up, and
        // computing each one from the stale reading would collapse them all
        // into a single step.
        const stepRaw = Math.max(
            1, Math.round(maxRaw * Settings.brightnessStepPercentage / 100))

        applyRaw(targetRaw + steps * stepRaw)
    }

    // ────── Internals ──────
    property string deviceName: ""
    property int maxRaw: 0
    property int rawValue: 0
    property int targetRaw: 0

    function applyRaw(raw) {
        const floor = Math.ceil(maxRaw * Settings.brightnessMinPercentage / 100)

        root.targetRaw = Math.max(floor, Math.min(maxRaw, Math.round(raw)))

        setter.running = false
        setter.command = [
            "brightnessctl", "--device", root.deviceName,
            "set", String(root.targetRaw)
        ]
        setter.running = true
    }

    // Anything that moves the backlight from outside — the function keys, or
    // another tool — shows up here and wins. Our own writes land back with
    // rawValue already equal to targetRaw, so they change nothing.
    onRawValueChanged: if (rawValue !== targetRaw) root.targetRaw = rawValue

    function resolveLevelIndex(value, thresholds) {
        let index = 0

        for (let i = 0; i < thresholds.length; i++) {
            if (value >= thresholds[i].threshold)
                index = i
            else
                break
        }

        return index
    }

    Process {
        id: setter
    }

    // ────── Device Discovery ──────
    // Indices under /sys/class/backlight are not fixed, and the name differs
    // per driver (intel_backlight, amdgpu_bl0, nvidia_0), so the directory is
    // read rather than hardcoded. The first entry wins; machines with a second
    // panel would need a Settings override.
    FolderListModel {
        id: backlightDirs

        folder: "file:///sys/class/backlight"
        showDirs: true
        showFiles: false
        showDotAndDotDot: false

        onStatusChanged: {
            if (status === FolderListModel.Ready && count > 0 && root.deviceName === "")
                root.deviceName = get(0, "fileName")
        }
    }

    FileView {
        path: root.deviceName
            ? "/sys/class/backlight/" + root.deviceName + "/max_brightness"
            : ""

        onLoaded: root.maxRaw = Number(text().trim())
    }

    FileView {
        id: actualFile

        path: root.deviceName
            ? "/sys/class/backlight/" + root.deviceName + "/actual_brightness"
            : ""

        // sysfs backlight does deliver inotify events, so this needs no timer
        // at all — verified against brightnessctl with no poller running.
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.rawValue = Number(text().trim())
    }

    // ────── Debug Trace ──────
    // readonly property string logLine:
    //     "BACKLIGHT: " + value + "% " + level + " " + icon
    //     + " (" + targetRaw + "/" + maxRaw + " on " + deviceName + ")"

    // onLogLineChanged: if (available) console.log(logLine)
}
