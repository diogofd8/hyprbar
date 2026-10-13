pragma Singleton

import Quickshell

Singleton {
    // ────── General Popup Layout Properties ──────

    // ────── Notification Toast Popup Properties ──────
    readonly property int notificationPopupSpacing: 4
    readonly property int notificationPopupMarginY: 4
    readonly property int notificationPopupMarginX: 0

    readonly property int notificationPopupWidth: 384
    readonly property int notificationPopupPaddingX: 6
    readonly property int notificationPopupPaddingY: 6

    readonly property int notificationMainVMargin: 2
    readonly property int notificationPopupVSpacing: 4
    readonly property int notificationPopupHeaderHSpacing: 8
    readonly property int notificationPopupAttentionHSpacing: 4

    readonly property int notificationPopupFontSize: 12
    readonly property int notificationPopupHeaderFontSize: 12
    readonly property int notificationPopupTitleFontSize: 13
    readonly property int notificationPopupAppIconSize: 16
    readonly property int notificationPopupHeaderIconSize: 14

    readonly property int notificationPopupAttentionBarWidth: 2
    readonly property int notificationPopupImageHeight: 120
    readonly property real notificationPopupImageSourceScale: 2

    readonly property real notificationActionButtonPadding: 5
    readonly property real notificationCountdownRingWidth: 2
    readonly property real notificationCountdownRingMargin: 7

    readonly property var notificationPopupIcon: ({
        clear: "󰅖"
    })
}
