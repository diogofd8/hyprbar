import QtQuick

import qs
import qs.components
import qs.core as Core

ChevronButton {
    contentLeftPadding: 2
    contentRightPadding: 6

    leftCap: Core.ChevronGeometry.Cap.Point
    rightCap: Core.ChevronGeometry.Cap.Flat

    bgFill: "transparent"
    onLeftClicked: Core.Actions.powerMenu()

    Glyph {
        icon: Settings.powerMenuIcon
        iconSize: Settings.buttonFontSize
        verticalOffset: 0
    }
}