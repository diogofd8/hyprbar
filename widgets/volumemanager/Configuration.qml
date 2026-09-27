pragma Singleton

import Quickshell

Singleton {
    // ────── General ──────
    readonly property int widgetBoxPadding: 8

    readonly property int mixerTogglerSpacing: 0
    readonly property int topBarSpacing: 6
    readonly property int topBarPadding: 18
    readonly property int mainColumnGap: 12
    readonly property int sectionSpacing: 16

    readonly property real mainButtonSize: 18
    readonly property int applicationIconSize: 24
    readonly property real secondaryButtonSize: 16
    readonly property real columnLabelFontSize: 11
    readonly property real subTextFontSize: 11
    readonly property int transitionMs: 100

    // ------- Power Entries -------
    readonly property real volEntryNameFontSize: 12
    readonly property int volEntryRowSpacing: 8
    readonly property int volEntryExpandedRowSpacing: 2
    readonly property int volEntryPadding: 3

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
    readonly property int listMaxHeight: 440
}
