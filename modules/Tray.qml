import QtQuick

import Quickshell.Services.SystemTray as TrayService

import qs
import qs.components
import qs.widgets
import qs.core as Core
import qs.widgets.systemtray as SysTrayUI

ChevronButton {
    id: root

    contentLeftPadding: 5
    contentRightPadding: 2

    leftCap: Core.ChevronGeometry.Cap.Notch
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.bgTint1
    hoverOpacity: 2 * Settings.colors.hoverOpacity

    readonly property bool trayHasContent: TrayService.SystemTray.items.values.some(
        item => SysTrayUI.Configuration.isVisible(item)
    )

    onLeftClicked: sysTray.toggle()

    Glyph {
        id: togglerIcon

        icon: Settings.systemTrayIcon
        useMetrics: true
        rotation: sysTray.isOpen ? 180 : 0

        Behavior on rotation {
            NumberAnimation {
                duration: Settings.dropDownTransitionMs
                easing.type: Easing.InOutCubic
            }
        }

        NotificationDot {
            visible: sysTray.isOpen? 0 : root.trayHasContent
            dotColor: Settings.colors.accentAlert
            dotBgColor: Settings.colors.bgTint1
        }
    }

    DropDown {
        id: sysTray
        anchorItem: root

        SystemTray {
            id: systemTray
            anchors.fill: parent

            onPlatformMenuOpened: sysTray.holdOpen = true
            onPlatformMenuClosed: sysTray.holdOpen = false

            onDismissRequested: {
                sysTray.close()
            }
        }
    }
}
