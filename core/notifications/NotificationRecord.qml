import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs

Scope {
    id: root

    required property var owner
    required property Notification notification
    property date receivedAt
    property bool alive: true
    property bool popupVisible: false
    property bool popupHovered: false
    property bool popupPinned: false
    // Zero while expiry is stopped; the toast uses this deadline for its ring.
    property double popupExpiresAt: 0
    // Native closure can precede deferred destruction of the QML record/cards.
    readonly property int notificationId: notification?.id ?? 0
    readonly property string appName: notification?.appName || "Notification"
    readonly property string desktopEntry: notification?.desktopEntry ?? ""
    readonly property string appIcon: notification?.appIcon ?? ""
    readonly property string summary: notification?.summary ?? ""
    readonly property string body: notification?.body ?? ""
    readonly property string image: notification?.image ?? ""
    readonly property int urgency: notification?.urgency ?? 1
    readonly property var actions: notification?.actions ?? []
    // Quickshell 0.3.2 passes through the D-Bus timeout in milliseconds.
    readonly property real timeout: !notification ? 0 : notification.expireTimeout >= 0
        ? notification.expireTimeout : root.urgency === NotificationUrgency.Critical
        ? 0 : root.urgency === NotificationUrgency.Low
        ? Settings.notificationLowTimeoutMs : Settings.notificationTimeoutMs

    function restartTimeout(): void {
        expiry.stop()
        root.popupExpiresAt = 0
        if (root.popupVisible && !root.popupHovered && !root.popupPinned && root.timeout > 0) {
            expiry.start()
            root.popupExpiresAt = Date.now() + expiry.interval
        }
    }
    function refresh(): void {
        if (root.alive)
            root.owner.updated(root)
    }

    onPopupVisibleChanged: restartTimeout()
    onPopupHoveredChanged: restartTimeout()
    onPopupPinnedChanged: restartTimeout()
    Timer {
        id: expiry
        interval: Math.max(1, root.timeout)
        onTriggered: root.owner.hidePopup(root)
    }
    Connections {
        target: root.notification
        // A replacement updates the same native object instead of emitting a
        // new notification. Coalesce its property changes into one list move.
        function onSummaryChanged() { Qt.callLater(root.refresh) }
        function onBodyChanged() { Qt.callLater(root.refresh) }
        function onActionsChanged() { Qt.callLater(root.refresh) }
        function onHintsChanged() { Qt.callLater(root.refresh) }
        function onAppNameChanged() { Qt.callLater(root.refresh) }
        function onDesktopEntryChanged() { Qt.callLater(root.refresh) }
        function onAppIconChanged() { Qt.callLater(root.refresh) }
        function onExpireTimeoutChanged() { Qt.callLater(root.refresh) }
        function onUrgencyChanged() { Qt.callLater(root.refresh) }
        function onTransientChanged() { Qt.callLater(root.refresh) }
        function onImageChanged() { Qt.callLater(root.refresh) }
        function onClosed(reason) { root.owner.forget(root) }
    }
}
