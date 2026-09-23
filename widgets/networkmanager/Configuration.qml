pragma Singleton

import Quickshell

Singleton {
    // ────── General ──────
    readonly property int widgetBoxPadding: 8

    readonly property int topBarPadding: 6
    readonly property int mainColumnGap: 12
    readonly property int sectionSpacing: 16

    readonly property real mainButtonSize: 18
    readonly property real secondaryButtonSize: 16
    readonly property real textButtonFontSize: 12
    readonly property real columnLabelFontSize: 11
    readonly property real subTextFontSize: 11
    readonly property real nwNameFontSize: 12
    readonly property int transitionMs: 100

    // ------- Network Entries -------
    readonly property int nwEntryRowSpacing: 3
    readonly property int nwEntryExpandedRowSpacing: 2
    readonly property int nwEntryPadding: 3

    // ────── Icons ──────
    readonly property var nwWifiProtectedIcon: [
        "󱛏", "󱛋", "󱛌", "󱛍", "󱛎"
    ]
    readonly property var nwWifiOpenIcon: [
        "󰤬", "󰤡", "󰤤", "󰤧", "󰤪"
    ]
    readonly property string nmConnectionEditorIcon: ""
    readonly property string nmConnectionRefreshIcon: "󰓦"
    readonly property string nwWifiIcon: ""
    readonly property string nwEthernetIcon: "󰈁"
    readonly property string nwEditConnectionIcon: ""
    readonly property string nwConnectIcon: ""
    readonly property string nwDisconnectIcon: ""
    readonly property string nwExpandIcon: ""



    readonly property int contentWidth: 368
    readonly property int listMaxHeight: 440
}
