import QtQuick

import qs
import qs.components
import qs.core as Core
import qs.widgets

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
        hoverOpacity: Settings.colors.hoverOpacityStrong

        onScrolled: steps => Core.Backlight.stepBrightness(steps)
        onLeftClicked: brightnessManager.toggle()
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

    Binding {
        target: Core.Backlight
        property: "discoveryActive"
        value: brightnessManager.contentActive
    }

    DropDown {
        id: brightnessManager
        spacing: 1
        anchorItem: root

        BrightnessManager {
            anchors.fill: parent
        }
    }
}
