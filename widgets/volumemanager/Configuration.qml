pragma Singleton

import Quickshell

Singleton {
    // ────── Device Labels ──────
    readonly property string builtInSpeakersLabel: "Built-in Speakers"
    readonly property string internalMicrophoneLabel: "Internal Microphone"

    // ────── Icons ──────
    readonly property var outputMuteState: ["󰕾", "󰖁"]
    readonly property var inputMuteState: ["", ""]
    readonly property var deviceSelectedState: ["", ""]
    readonly property var volMixerMode: ({
        "devices": "󱡫",
        "applications": ""
    })
    readonly property string volumeSettingsIcon: ""
    readonly property string volEntrySettingsIcon: ""
    readonly property string applicationFallbackIcon: ""

    readonly property int contentWidth: 270
}
