import QtQuick

import qs
import qs.components
import qs.core as Core

Row {
    id: root
    spacing: -Core.ChevronGeometry.calcCapWidth(height)

    ChevronButton {
        height: root.height
        contentLeftPadding: 6
        contentRightPadding: 2

        leftCap: Core.ChevronGeometry.Cap.Notch
        rightCap: Core.ChevronGeometry.Cap.Point

        bgFill: Settings.colors.bgTint4
        hoverOpacity: 2 * Settings.colors.hoverOpacity

        onLeftClicked: Core.Actions.weatherPopUp()

        Row {
            spacing: 8

            Glyph {
                text: Core.WeatherParse.icon
            }

            Temperature {
                value: Core.WeatherParse.temperatureText
            }
        }
    }
}
