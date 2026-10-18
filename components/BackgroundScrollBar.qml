import QtQuick
import QtQuick.Controls.Basic as Controls

import qs

// Keep the native ScrollBar interaction and sizing, and project its thumb.
Controls.ScrollBar {
    id: root

    contentItem: BackgroundRectangle {
        implicitWidth: root.interactive ? 6 : 2
        implicitHeight: implicitWidth
        radius: width / 2
        color: root.pressed ? Settings.colors.background.accent : Settings.colors.background.highlight
        opacity: root.policy === Controls.ScrollBar.AlwaysOn || (root.active && root.size < 1) ? 0.75 : 0

        // Match the Basic style: appear immediately, linger, then fade.
        Behavior on opacity {
            enabled: !root.active && root.policy !== Controls.ScrollBar.AlwaysOn
            SequentialAnimation {
                PauseAnimation { duration: Motion.scrollBarIdleDelayMs }
                NumberAnimation { duration: Motion.normalMs }
            }
        }
    }

    background: null
}
