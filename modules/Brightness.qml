import QtQuick

import qs
import qs.components
import qs.core as Core

Row {
    id: root
    spacing: -Core.ChevronGeometry.calcCapWidth(height)

    ChevronButton {
        height: root.height
        contentLeftPadding: 5
        contentRightPadding: 2

        leftCap: Core.ChevronGeometry.Cap.Notch
        rightCap: Core.ChevronGeometry.Cap.Point

        bgFill: Settings.colors.bgTint3
        hoverOpacity: 2 * Settings.colors.hoverOpacity

        onScrolled: steps => Core.Backlight.stepBrightness(steps)
        onRightClicked: Core.Actions.toggleDarkMode()

        Glyph {
            icon: Core.Backlight.icon
            verticalOffset: Settings.inducedVerticalOffset
        }
    }

    Chevron {
        height: root.height
        contentLeftPadding: 2
        contentRightPadding: 3

        leftCap: Core.ChevronGeometry.Cap.Notch
        rightCap: Core.ChevronGeometry.Cap.Point

        bgFill: Settings.colors.bgTint2

        Percentage {
            height: root.height
            value: Core.Backlight.value
        }
    }
}

