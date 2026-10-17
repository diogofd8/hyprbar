pragma Singleton

import Quickshell

Singleton {
    readonly property real powerMenuEdgeVerticalPos: 0.5
    readonly property real powerMenuEdgeMargin: 0
    readonly property real powerMenuDimOpacity: 0.6

    readonly property real powerMenuPadding: 0
    readonly property real powerActionsVSpacing: -powerActionBtnPadding / 2
    readonly property real powerActionBtnHeight: 48
    readonly property real powerActionIconSz: 24
    readonly property real powerActionLabelFontSz: 16
    readonly property real powerActionBtnLeftPadding: 6
    readonly property real powerActionBtnRightPadding: 12
    readonly property real powerActionLabelPaddingX: 16
    readonly property real powerActionBtnPadding: 4
    readonly property real confirmActionsHMargin: 2

    readonly property real confirmActionBtnWidth: 34
    readonly property real confirmActionBtnHeight: 48
    readonly property int confirmActionIconSz: 16
    readonly property real confirmActionBtnLeftPadding: 4
    readonly property real confirmActionBtnRightPadding: 3
    readonly property real confirmActionsVSpacing: 2

    readonly property var powerActionEntries: [
        { action: "lock", name: "Lock", icon: "󰌾" },
        { action: "suspend", name: "Suspend", icon: "󰤄" },
        { action: "reboot", name: "Reboot", icon: "" },
        { action: "poweroff", name: "Power Off", icon: "" },
        { action: "logout", name: "Log Out", icon: "" }
    ]
    readonly property var confirmActionIcon: ({
        yes: "",
        no: "",
    })
}
