import QtQuick
import Quickshell

import qs
import qs.components
import qs.core as Core

Row {
    id: root
    spacing: -Core.ChevronGeometry.calcCapWidth(height)

    ChevronButton {
        height: root.height
        contentLeftPadding: 4
        contentRightPadding: 0

        leftCap: Core.ChevronGeometry.Cap.Point
        rightCap: Core.ChevronGeometry.Cap.Notch

        bgFill: Settings.colors.bgTint1
        hoverOpacity: 0

        onLeftClicked: Core.Actions.vitalsPopUp()

        Row {
            spacing: 6

            Glyph {
                text: Settings.ramStressIcon
                useMetrics: false
            }

            Percentage {
                value: Math.round(Core.SystemStats.ramStress.overall.value)
                padding: 4
            }
        }
    }

    ChevronButton {
        height: root.height
        contentLeftPadding: 2
        contentRightPadding: 0

        leftCap: Core.ChevronGeometry.Cap.Point
        rightCap: Core.ChevronGeometry.Cap.Notch

        bgFill: Settings.colors.bgTint2
        hoverOpacity: 0

        onLeftClicked: Core.Actions.vitalsPopUp()

        Row {
            spacing: 0

            Glyph {
                text: Settings.cpuStressIcon
                useMetrics: false
            }

            Percentage {
                value: Math.round(Core.SystemStats.cpuStress.overall.value)
                padding: 6
            }
        }
    }

    ChevronButton {
        height: root.height
        contentLeftPadding: 2
        contentRightPadding: 5

        leftCap: Core.ChevronGeometry.Cap.Point
        rightCap: Core.ChevronGeometry.Cap.Notch

        bgFill: Settings.colors.bgTint3
        hoverOpacity: 0

        onLeftClicked: Core.Actions.vitalsPopUp()

        Row {
            spacing: 6

            Glyph {
                text: Settings.cpuTempIcon[2]
            }

            Temperature {
                value: Math.round(Core.SystemStats.cpuTemperature.overall.value)
            }
        }
    }
}
