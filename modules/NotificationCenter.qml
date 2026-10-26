import QtQuick

import qs
import qs.components
import qs.core as Core
import qs.widgets as Widgets

ChevronButton {
    id: root

    contentLeftPadding: 5
    contentRightPadding: 2

    leftCap: Core.ChevronGeometry.Cap.Notch
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.background.tint3
    hoverOpacity: Settings.colors.background.hoverOpacityStrong

    onLeftClicked: Core.Actions.notificationMenu()
    onRightClicked: Core.Notifications.clearAll()

    Glyph {
        icon: Settings.notificationIcon
        NotificationDot {
            visible: !notificationCenter.isOpen && Core.Notifications.count > 0
            dotColor: Settings.colors.foreground.alert
            dotBgColor: root.bgFill
        }
    }

    DropDown {
        id: notificationCenter
        anchorItem: root
        Widgets.NotificationManager {
            anchors.fill: parent

            onDismissRequested: notificationCenter.close()
        }
    }

    Connections {
        target: Core.Notifications
        function onOpenRequested() {
            notificationCenter.toggle()
        }
    }

    Binding {
        target: Core.Notifications
        property: "centerOpen"
        value: notificationCenter.isOpen
    }
}
