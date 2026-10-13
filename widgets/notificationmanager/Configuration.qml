pragma Singleton

import Quickshell

Singleton {
    // ────── Icons ──────
    readonly property var nfDoNotDisturbIcon: ({
        on: "󰂛",
        off: "󰂞"
    })
    readonly property string nfExpandIcon: ""
    readonly property string nfClearAllIcon: ""
    readonly property string nfReadIcon: ""

    // ────── Exclusive Notification Sizing ──────
    readonly property real nfAttentionBarWidth: 2
    readonly property real nfCompactTitleBodyRatio: 0.8
    readonly property real nfScrollBarReserve: 10

    readonly property real notificationCompactHeight: 280
    readonly property real notificationImageHeight: 120
    readonly property real nfImageSourceScale: 2

    readonly property real contentWidth: 420
}
