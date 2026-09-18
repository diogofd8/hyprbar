import QtQuick
import QtQuick.Layouts

import qs
import qs.core as Core

RowLayout {
    id: root

    property string value: ""
    property real verticalOffset: Settings.inducedVerticalOffset

    readonly property real degreeUnitSpacing: -1.75
    readonly property real labelVerticalOffset:
        (degreeMetrics.ascent - labelMetrics.ascent) / 2

    spacing: 0

    Text {
        text: root.value
        color: Settings.colors.fgMain
        font.family: Settings.labelFontFamily
        font.pixelSize: Settings.labelFontSize

        Layout.topMargin: -root.labelVerticalOffset + root.verticalOffset
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: "º"
        color: Settings.colors.fgMain
        font.family: Settings.labelFontFamily
        font.pixelSize: Settings.iconFontSize

        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: Core.WeatherParse.getTemperatureUnitLetter()
        color: Settings.colors.fgMain
        font.family: Settings.labelFontFamily
        font.pixelSize: Settings.labelFontSize

        Layout.leftMargin: root.degreeUnitSpacing
        Layout.topMargin: -root.labelVerticalOffset + root.verticalOffset
        Layout.alignment: Qt.AlignVCenter
    }

    FontMetrics {
        id: labelMetrics

        font.family: Settings.labelFontFamily
        font.pixelSize: Settings.labelFontSize
    }

    FontMetrics {
        id: degreeMetrics

        font.family: Settings.labelFontFamily
        font.pixelSize: Settings.iconFontSize
    }
}