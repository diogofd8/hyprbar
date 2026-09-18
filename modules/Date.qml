import QtQuick
import Quickshell

import qs
import qs.components
import qs.core as Core

Row {
    id: root
    spacing: -Core.ChevronGeometry.calcCapWidth(height)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ChevronButton {
        height: root.height
        contentLeftPadding: 2
        contentRightPadding: 4

        leftCap: Core.ChevronGeometry.Cap.Point
        rightCap: Core.ChevronGeometry.Cap.Notch

        bgFill: Settings.colors.bgTint3
        hoverOpacity: 2 * Settings.colors.hoverOpacity

        onLeftClicked: Core.Actions.calendarPopUp()
        onRightClicked: Core.Actions.calendarFullPopUp()

        Text {
            y: Settings.inducedVerticalOffset

            text: Qt.formatDateTime(clock.date, "ddd").toUpperCase()
            color: Settings.colors.fgMain
            font.family: Settings.labelFontFamily
            font.pixelSize: Settings.smallCapsFontSize
            font.weight: Font.Bold
        }
    }

    Chevron {
        height: root.height
        contentLeftPadding: 2
        contentRightPadding: 4

        leftCap: Core.ChevronGeometry.Cap.Point
        rightCap: Core.ChevronGeometry.Cap.Notch

        bgFill: Settings.colors.bgTint4

        Row {
            spacing: 5
            y: Settings.inducedVerticalOffset

            Text {
                text: Qt.formatDateTime(clock.date, "MMM")
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.labelFontSize
            }

            Circle {
                diameter: 2
                color: Settings.colors.fgMain
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: Qt.formatDateTime(clock.date, "d")
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.labelFontSize
            }
        }
    }
}
