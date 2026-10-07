pragma Singleton

import Quickshell

Singleton {
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
    readonly property string nwSendIcon: "󰒊"
    readonly property string nwDismissIcon: "󰅖"

    readonly property int contentWidth: 250
}
