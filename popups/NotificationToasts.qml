import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Wayland

import qs
import qs.core as Core
import qs.components

PanelWindow {
    id: root

    readonly property Item backgroundTarget: toastBackground.paintTarget

    WlrLayershell.namespace: "hyprbar-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }

    margins {
        top: Settings.barHeight + PopupConfiguration.notificationPopupMarginY
        right: PopupConfiguration.notificationPopupMarginX
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Core.Notifications.popupModel.count > 0
    implicitWidth: PopupConfiguration.notificationPopupWidth
    implicitHeight: Math.max(1, root.screen.height - Settings.barHeight - 2 * PopupConfiguration.notificationPopupMarginY)
    mask: Region { item: viewport }

    Flickable {
        id: viewport

        readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: viewport }

        width: parent.width
        height: Math.min(contents.implicitHeight, parent.height)
        contentWidth: width
        contentHeight: contents.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        BackgroundSurface {
            id: toastBackground
            parent: viewport
            width: viewport.width
            height: viewport.height
            z: -1
        }

        Controls.ScrollBar.vertical: BackgroundScrollBar {}

        Column {
            id: contents

            width: parent.width
            spacing: PopupConfiguration.notificationPopupSpacing

            Repeater {
                model: Core.Notifications.popupModel

                NotificationToast {
                    id: toast

                    width: contents.width

                    onHoveredChanged: {
                        if (toast.entry)
                            toast.entry.popupHovered = toast.hovered
                    }
                }
            }
        }
    }
}
