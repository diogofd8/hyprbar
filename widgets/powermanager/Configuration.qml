pragma Singleton

import Quickshell

Singleton {
    // ────── General ──────
    readonly property int widgetBoxPadding: 8

    readonly property int topBarSpacing: 6
    readonly property int mainColumnGap: 12
    readonly property int sectionSpacing: 16

    readonly property real mainButtonSize: 18
    readonly property real secondaryButtonSize: 16
    readonly property real columnLabelFontSize: 11
    readonly property real subTextFontSize: 11
    readonly property int transitionMs: 100

    // ────── Profile Control Backend ──────
    // tlp-pd implements the standard Power Profiles API while keeping TLP as
    // the underlying engine. "tlp" remains available for direct commands on
    // systems where those commands have been separately authorised.
    readonly property string powerProfileBackend: "power-profiles-daemon"

    // ------- Power Entries -------
    readonly property real pwrEntryNameFontSize: 12
    readonly property int pwrEntryRowSpacing: 3
    readonly property int pwrEntryExpandedRowSpacing: 2
    readonly property int pwrEntryPadding: 3

    // ────── Battery Names ──────
    readonly property string internalBat: "01AV421"
    readonly property string externalBat: "01AV427"

    // ────── Icons ──────
    readonly property var batteryStatus: [
        { icon: "󰔵", status: "charging" },
        { icon: "󰔳", status: "discharging" },
        { icon: "󰄉", status: "waiting" },
        { icon: "󰡳", device: "empty" },
        { icon: "󰡴", device: "full" },
    ]
    readonly property var powerMode: [
        { icon: "󰌪", mode: "powersave" },
        { icon: "󰗑", mode: "balanced" },
        { icon: "", mode: "performance" },
    ]

    readonly property int contentWidth: 270
    readonly property int listMaxHeight: 440
}
