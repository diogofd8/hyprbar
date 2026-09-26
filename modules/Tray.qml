import QtQuick

import qs
import qs.components
import qs.core as Core

ChevronButton {
    id: root

    contentLeftPadding: 5
    contentRightPadding: 2

    leftCap: Core.ChevronGeometry.Cap.Notch
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.bgTint1
    hoverOpacity: 2 * Settings.colors.hoverOpacity

    onLeftClicked: console.log(true);

    Glyph {
        icon: Settings.systemTrayIcon
    }
}
