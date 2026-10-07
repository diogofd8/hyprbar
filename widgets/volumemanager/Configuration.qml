pragma Singleton

import Quickshell

Singleton {
    // ────── Device Labels ──────
    readonly property string builtInSpeakersLabel: "Built-in Speakers"
    readonly property string internalMicrophoneLabel: "Internal Microphone"

    // ────── Icons ──────
    readonly property string outputUnmutedIcon: "󰕾"
    readonly property string outputMutedIcon: "󰖁"
    readonly property string inputUnmutedIcon: ""
    readonly property string inputMutedIcon: ""
    readonly property string deviceSelectedIcon: ""
    readonly property string deviceUnselectedIcon: ""
    readonly property var volMixerMode: ({
        "devices": "󱡫",
        "applications": ""
    })
    readonly property string volumeSettingsIcon: ""
    readonly property string volEntrySettingsIcon: ""
    readonly property string applicationFallbackIcon: ""

    readonly property int contentWidth: 270
}
