import QtQuick

import qs
import qs.components
import qs.core as Core
import qs.widgets as Widgets

Row {
    id: root
    spacing: -Core.ChevronGeometry.calcCapWidth(height)

    ChevronButton {
        height: root.height
        contentLeftPadding: 4
        contentRightPadding: 0

        leftCap: Core.ChevronGeometry.Cap.Point
        rightCap: Core.ChevronGeometry.Cap.Notch

        bgFill: Settings.colors.background.tint1
        hoverOpacity: 0

        onLeftClicked: vitalsViewer.toggle()
        onRightClicked: Core.Actions.vitalsPopUp()

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

        bgFill: Settings.colors.background.tint2
        hoverOpacity: 0

        onLeftClicked: vitalsViewer.toggle()
        onRightClicked: Core.Actions.vitalsPopUp()

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

        bgFill: Settings.colors.background.tint3
        hoverOpacity: 0

        onLeftClicked: vitalsViewer.toggle()
        onRightClicked: Core.Actions.vitalsPopUp()

        Row {
            spacing: 6

            Glyph {
                text: Settings.cpuTempIcon[Core.SystemStats.cpuTemperature.overall.state]
            }

            Temperature {
                value: Math.round(Core.SystemStats.cpuTemperature.overall.value)
            }
        }
    }

    DropDown {
        id: vitalsViewer
        anchorItem: root

        Widgets.VitalsViewer {
            anchors.fill: parent
        }
    }
}
