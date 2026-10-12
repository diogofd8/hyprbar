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
            root.finishDismissal()
            root.dismissProgress = 0
        }
    }

    // A surface may unload before its swipe finishes. Keep the clear action.
    Component.onDestruction: root.finishDismissal()

    // ────── Helper Functions ──────
    function dismissEntries(entries): void {
        if (root.dismissing || entries.length === 0)
            return

        // New arrivals during the swipe must survive this clear.
        root.pendingEntries = entries.slice()
        swipe.start()
    }

    function finishDismissal(): void {
        const entries = root.pendingEntries
        root.pendingEntries = []

        if (root.service) {
            for (const entry of entries)
                root.service.dismiss(entry)
        }
    }
}
