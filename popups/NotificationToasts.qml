import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Wayland

import qs
import qs.core as Core

PanelWindow {
    id: root

    WlrLayershell.namespace: "hyprbar-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }

    margins {
        top: Settings.barHeight + Settings.notificationPopupMargin
        right: Settings.notificationPopupMargin
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Core.Notifications.popupModel.count > 0
    implicitWidth: Settings.notificationPopupWidth
    implicitHeight: root.popupHeight()

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contents.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Controls.ScrollBar.vertical: Controls.ScrollBar {}

        Column {
            id: contents

            width: parent.width
            spacing: Settings.notificationPopupSpacing

            Repeater {
                model: Core.Notifications.popupModel

                NotificationToast {
                    id: toast

                    width: contents.width
                    popup: true

                    onHoveredChanged: {
                        if (toast.entry)
                            toast.entry.popupHovered = toast.hovered
                    }
                }
            }
        }
    }

    // ────── Helper Functions ──────
    function popupHeight(): real {
        const margin = Settings.notificationPopupMargin
        const available = root.screen.height - Settings.barHeight - 2 * margin
        return Math.min(contents.implicitHeight, available)
    }
}
