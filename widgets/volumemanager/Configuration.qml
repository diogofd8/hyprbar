pragma Singleton

import Quickshell

Singleton {
    // The laptop's built-in PipeWire nodes. These are deliberately names,
    // rather than numeric IDs, because PipeWire object IDs are session-local.
    readonly property string defaultInput:
        "alsa_input.pci-0000_00_1f.3.analog-stereo"
    readonly property string defaultOuput:
        "alsa_output.pci-0000_00_1f.3.analog-stereo"

    // ────── Icons ──────
    readonly property var outputMuteState: ["󰕾", "󰖁"]
    readonly property var inputMuteState: ["", ""]
    readonly property var deviceSelectedState: ["", ""]
    readonly property var volMixerMode: [
        { icon: "󱡫", mode: "devices" },
        { icon: "", mode: "applications" }
    ]
    readonly property string volumeSettingsIcon: ""
    readonly property string volEntrySettingsIcon: ""
    readonly property string applicationFallbackIcon: ""

    readonly property int contentWidth: 270
}
