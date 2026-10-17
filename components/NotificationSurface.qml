import QtQuick
import QtQuick.Controls as Controls

import qs
import qs.components
import qs.core as Core

// Animate presentation here; the service still owns notification removal.
Controls.Pane {
    id: root

    property var service: Core.Notifications
    readonly property bool dismissing: pendingEntries.length > 0
    property var pendingEntries: []
    property bool popupOnly: false
    property real dismissProgress: 0

    enabled: !root.dismissing
    opacity: 1 - root.dismissProgress
    transform: Translate { x: root.width * root.dismissProgress }

    Anim {
        id: swipe

        target: root
        property: "dismissProgress"
        to: 1
        duration: Motion.notificationDismissMs
        easing.bezierCurve: Motion.exitCurve

        onFinished: {
            // Removal can destroy this QML context. Only surviving surfaces
            // should reset, after the model has finished removing entries.
            Qt.callLater(root.resetDismissProgress)
            root.finishDismissal()
        }
    }

    // A surface may unload before its swipe finishes. Keep the clear action.
    Component.onDestruction: root.finishDismissal()

    // ────── Helper Functions ──────
    function dismissEntries(entries, popupOnly = false): void {
        if (root.dismissing || entries.length === 0)
            return

        // New arrivals during the swipe must survive this clear.
        root.pendingEntries = entries.slice()
        root.popupOnly = popupOnly
        swipe.start()
    }

    function cancelDismissal(): void {
        swipe.stop()
        root.pendingEntries = []
        root.popupOnly = false
        root.resetDismissProgress()
    }

    function finishDismissal(): void {
        const entries = root.pendingEntries
        const popupOnly = root.popupOnly
        root.pendingEntries = []
        root.popupOnly = false

        if (root.service) {
            for (const entry of entries) {
                if (popupOnly)
                    root.service.hidePopup(entry)
                else
                    root.service.dismiss(entry)
            }
        }
    }

    function resetDismissProgress(): void {
        root.dismissProgress = 0
    }
}
