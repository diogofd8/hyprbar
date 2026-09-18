import QtQuick

import qs
import qs.components
import qs.core as Core

ChevronButton {
    contentLeftPadding: 6
    contentRightPadding: 4

    leftCap: Core.ChevronGeometry.Cap.Flat
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: "transparent"
    onLeftClicked: Core.Actions.launcher()

    Glyph {
        icon: Settings.launcherIcon
        iconSize: Settings.buttonFontSize
        verticalOffset: 0
    }
}
