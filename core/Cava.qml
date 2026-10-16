pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // The visible consumer owns demand; no capture process runs by default.
    property bool active: false
    property int barCount: 0
    property int frameRate: 24
    property var levels: []

    readonly property int outputBarCount: Math.max(0, Math.min(512, root.barCount))
    readonly property int outputFrameRate: Math.max(1, Math.min(60, root.frameRate))
    readonly property string configuration: root.createConfiguration()

    onActiveChanged: {
        if (!root.active)
            root.levels = []
    }

    onConfigurationChanged: {
        root.levels = []
        // A starting process gets the latest configuration in onStarted.
        // Restart only after its previous configuration has been sent.
        if (root.active && root.outputBarCount > 0
            && analyzer.running && !analyzer.stdinEnabled)
            analyzer.exec(analyzer.command)
    }

    Process {
        id: analyzer
        command: ["cava", "-p", "/dev/stdin"]
        running: root.active && root.outputBarCount > 0
        stdinEnabled: true

        // Give each instance its configuration without touching ~/.config/cava.
        // Closing stdin supplies the EOF required by CAVA's INI parser.
        onStarted: {
            analyzer.write(root.configuration)
            analyzer.stdinEnabled = false
        }

        onExited: analyzer.stdinEnabled = true
        onRunningChanged: {
            if (!analyzer.running)
                root.levels = []
        }

        stdout: SplitParser {
            onRead: data => root.readFrame(data)
        }

        stderr: SplitParser {
            onRead: data => console.warn("CAVA:", data)
        }
    }

    function createConfiguration(): string {
        return [
            "[general]",
            "framerate = " + root.outputFrameRate,
            "bars = " + root.outputBarCount,
            "[input]",
            "method = pipewire",
            "source = auto",
            "[output]",
            "method = raw",
            "raw_target = /dev/stdout",
            "data_format = ascii",
            "ascii_max_range = 1000",
            "channels = mono",
            "mono_option = average",
            "bar_delimiter = 59",
            "frame_delimiter = 10",
            ""
        ].join("\n")
    }

    function readFrame(data: string): void {
        if (!root.active || !analyzer.running || root.outputBarCount === 0)
            return

        const values = data.trim().split(";")
        if (values[values.length - 1] === "")
            values.pop()
        if (values.length !== root.outputBarCount)
            return

        const frame = []
        for (const value of values) {
            const amplitude = Number(value)
            if (value === "" || !Number.isFinite(amplitude))
                return
            frame.push(Math.max(0, Math.min(1, amplitude / 1000)))
        }
        root.levels = frame
    }
}
