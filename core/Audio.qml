pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import qs

Singleton {
    id: root

    // ────── Public API ──────
    // {available, value, muted, state, level, headphones, icon, name, description}
    // `state` is what the view colours on: "default" or "muted". `level` is a
    // separate axis that only picks the icon, so a sink sitting at 0% but
    // unmuted still reads as "default".
    readonly property var sink: reading(Pipewire.defaultAudioSink, false)
    readonly property var source: reading(Pipewire.defaultAudioSource, true)

    readonly property bool ready: Pipewire.ready

    // Pipewire nodes are not bound by default: without this tracker their
    // volume and muted properties never update, and the module silently shows
    // whatever was true at startup forever.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // ────── Actions ──────
    function setVolume(percent) {
        const audio = audioOf(Pipewire.defaultAudioSink)

        if (audio)
            audio.volume = clampPercent(percent) / 100
    }

    // `steps` is a count, not a percentage: the view passes +1 / -1 and the
    // size of a step stays configuration, not UI.
    function stepVolume(steps) {
        setVolume(root.sink.value + steps * Settings.volumeStepPercentage)
    }

    function toggleMute() {
        const audio = audioOf(Pipewire.defaultAudioSink)

        if (audio)
            audio.muted = !audio.muted
    }

    function setSourceVolume(percent) {
        const audio = audioOf(Pipewire.defaultAudioSource)

        if (audio)
            audio.volume = clampPercent(percent) / 100
    }

    function stepSourceVolume(steps) {
        setSourceVolume(root.source.value + steps * Settings.volumeStepPercentage)
    }

    function toggleSourceMute() {
        const audio = audioOf(Pipewire.defaultAudioSource)

        if (audio)
            audio.muted = !audio.muted
    }

    // ────── Internals ──────
    function audioOf(node) {
        return node && node.ready && node.audio ? node.audio : null
    }

    function clampPercent(percent) {
        return Math.max(0, Math.min(100, Math.round(percent)))
    }

    function reading(node, isInput) {
        const audio = audioOf(node)

        if (!audio) {
            return {
                available: false,
                value: 0,
                muted: true,
                state: "muted",
                level: Settings.volumeLevelThresholds[0].state,
                headphones: false,
                icon: isInput ? Settings.volumeInputMicOffIcon : Settings.volumeMutedIcon,
                name: "",
                description: ""
            }
        }

        const percent = Math.round(audio.volume * 100)
        const muted = audio.muted
        const headphones = !isInput && isHeadphoneNode(node)
        const index = resolveLevelIndex(percent, Settings.volumeLevelThresholds)

        return {
            available: true,
            value: percent,
            muted: muted,
            state: muted ? "muted" : "default",
            level: Settings.volumeLevelThresholds[index].state,
            headphones: headphones,
            icon: resolveIcon(index, muted, headphones, isInput),
            name: node.name,
            description: node.description
        }
    }

    // Returns the index rather than the state name, so volumeCtrlIcon and
    // volumeLevelThresholds stay locked together — add a threshold and you
    // must add the icon that goes with it.
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

    function resolveIcon(levelIndex, muted, headphones, isInput) {
        if (isInput)
            return muted ? Settings.volumeInputMicOffIcon : Settings.volumeInputMicOnIcon

        if (headphones)
            return muted ? Settings.volumeHeadphoneMutedIcon : Settings.volumeHeadphoneIcon

        if (muted)
            return Settings.volumeMutedIcon

        return Settings.volumeCtrlIcon[Math.min(levelIndex, Settings.volumeCtrlIcon.length - 1)]
    }

    // Bluetooth and USB headsets say so on the node itself.
    function isHeadphoneNode(node) {
        const properties = node.properties

        if (properties) {
            if (properties["device.api"] === "bluez5"
                || properties["device.bus"] === "bluetooth")
                return true

            const formFactor = properties["device.form-factor"]

            if (formFactor === "headphone" || formFactor === "headset")
                return true

            const iconName = properties["device.icon-name"]

            if (iconName === "audio-headphones" || iconName === "audio-headset")
                return true
        }

        // The built-in 3.5mm jack is invisible on the node: inserting a plug
        // switches the ALSA *route* and leaves every node property untouched —
        // verified against a real insertion, not just a forced port. The active
        // port is the only thing that moves, and PipeWire does not publish it,
        // so it comes from pactl instead.
        return /headphone|headset/i.test(root.activePort)
    }

    // ────── Active Port ──────
    // Needed only for the analog jack above; everything else is node-level.
    property string activePort: ""

    readonly property string portQuery:
        "d=$(pactl get-default-sink); pactl list sinks"
        + " | awk -v d=\"$d\" '$1==\"Name:\"{c=($2==d)}"
        + " c&&/Active Port:/{print $3; exit}'"

    Process {
        id: portReader

        command: ["sh", "-c", root.portQuery]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.activePort = text.trim()
        }
    }

    // pactl reports a sink *and* a card event for every volume change, so
    // re-reading on each one would spawn a process per scroll tick. The port
    // itself changes only when hardware is plugged or unplugged, so coalesce.
    Timer {
        id: portDebounce

        interval: 150

        onTriggered: {
            portReader.running = false
            portReader.running = true
        }
    }

    Process {
        command: ["pactl", "subscribe"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                if (data.indexOf("on sink") >= 0 || data.indexOf("on card") >= 0)
                    portDebounce.restart()
            }
        }
    }

    // ────── Debug Trace ──────
    // readonly property string logLine:
    //     "AUDIO: sink " + sink.value + "% " + sink.state
    //     + " level=" + sink.level + " " + sink.icon
    //     + (sink.headphones ? " [headphones]" : "") + " port=" + activePort
    //     + " <" + sink.description + ">"
    //     + " | source " + source.value + "% " + source.state + " " + source.icon

    // onLogLineChanged: if (ready) console.log(logLine)
}
