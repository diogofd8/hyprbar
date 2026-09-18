import QtQuick

import qs
import qs.components
import qs.core as Core

ChevronButton {
    height: root.height
    contentLeftPadding: 5
    contentRightPadding: 3

    leftCap: Core.ChevronGeometry.Cap.Notch
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.bgTint1
    hoverOpacity: 2 * Settings.colors.hoverOpacity

    onLeftClicked: Core.Actions.notificationMenu()

    Glyph {
        icon: Settings.notificationIcon
    }
}