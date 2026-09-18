pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs

Singleton {
    id: root

    // ────── Public API ──────
    readonly property int repoCount: persist.repoCount
    readonly property int aurCount: persist.aurCount
    readonly property int count: root.repoCount + root.aurCount
    readonly property bool available: root.count > 0
    readonly property bool checking: root.requested || checker.running
    property bool updating: false
    readonly property real lastCheckedMs: persist.lastCheckedMs

    readonly property string state: {
        if (root.checking)
            return "checking"

        if (persist.failed)
            return "error"

        return root.available ? "available" : "uptodate"
    }

    readonly property string icon: {
        switch (root.state) {
        case "checking":
            return Settings.updateNotifierSyncIcon
        case "error":
            return Settings.updateNotifierErrorIcon
        case "available":
            return Settings.updateNotifierIcon[1]
        default:
            return Settings.updateNotifierIcon[0]
        }
    }

    // ────── Actions ──────
    function check(): void {
        if (root.checking)
            return

        root.requested = true
        watchdog.restart()
        checker.running = true
    }

    function update(): void {
        Quickshell.execDetached([root.scriptPath, "update"])

        root.updating = true
        sessionWatch.restart()
    }

    // ────── Internals ──────
    readonly property string scriptPath: Quickshell.shellPath("scripts/sys_update.sh")
    property bool requested: false

    PersistentProperties {
        id: persist

        reloadableId: "systemUpdate"

        property int repoCount: 0
        property int aurCount: 0
        property bool failed: false
        property real lastCheckedMs: 0
    }

    readonly property bool due:
        Date.now() - persist.lastCheckedMs >= Settings.updateCheckIntervalMs

    Timer {
        interval: Settings.updateCheckHeartbeatMs
        running: true
        repeat: true

        onTriggered: if (root.due) root.check()
    }

    Component.onCompleted: if (root.due) root.check()

    Process {
        id: checker

        command: [
            root.scriptPath, "check",
            "--timeout", String(Settings.updateCheckTimeoutS)
        ]

        stdout: StdioCollector {
            id: checkerOutput

            waitForEnd: true
        }

        onExited: exitCode => root.settle(exitCode, checkerOutput.text)
    }

    readonly property int watchdogGraceMs: 15000

    Timer {
        id: watchdog

        interval: Settings.updateCheckTimeoutS * 1000 + root.watchdogGraceMs

        onTriggered: {
            checker.running = false
            root.requested = false
            persist.failed = true
            persist.lastCheckedMs = Date.now()
        }
    }

    function settle(exitCode: int, output: string): void {
        const reading = root.parse(output)

        watchdog.stop()
        root.requested = false
        persist.lastCheckedMs = Date.now()

        if (!reading || exitCode === 2) {
            persist.failed = true
            return
        }

        persist.repoCount = reading.repo ?? 0
        persist.aurCount = reading.aur ?? 0
        persist.failed = false
    }

    function parse(output: string): var {
        if (!output)
            return null

        try {
            return JSON.parse(output)
        } catch (error) {
            return null
        }
    }

    // ────── Session Watch ──────
    // The update runs in a terminal this shell does not own
    Timer {
        id: sessionWatch

        interval: Settings.updateSessionPollIntervalMs
        repeat: true

        onTriggered: if (!sessionProbe.running) sessionProbe.running = true
    }

    Process {
        id: sessionProbe

        command: [root.scriptPath, "session"]

        onExited: exitCode => {
            if (exitCode === 0)
                return

            sessionWatch.stop()
            root.updating = false
            root.check()
        }
    }
}
