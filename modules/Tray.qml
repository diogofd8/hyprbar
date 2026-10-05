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
    hoverOpacity: root.trayHasContent ? Settings.colors.hoverOpacityStrong : 0
    enabled: root.trayHasContent

    readonly property bool trayHasContent: TrayService.SystemTray.items.values.some(
        item => SysTrayUI.Configuration.isVisible(item)
    )

    onLeftClicked: sysTray.toggle()

    Glyph {
        id: togglerIcon

        icon: Settings.systemTrayIcon
        opacity: root.trayHasContent ? 1 : Settings.colors.disabledOpacity
        useMetrics: true
        rotation: sysTray.isOpen ? 180 : 0

        Behavior on rotation { Anim { duration: Motion.fastMs } }

        NotificationDot {
            visible: !sysTray.isOpen && root.trayHasContent
            dotColor: Settings.colors.accentAlert
            dotBgColor: Settings.colors.bgTint1
        }
    }

    DropDown {
        id: sysTray
        spacing: 1
        anchorItem: root

        SystemTray {
            id: systemTray
            anchors.fill: parent

            onPlatformMenuOpened: sysTray.holdOpen = true
            onPlatformMenuClosed: sysTray.holdOpen = false
        }
    }
}
