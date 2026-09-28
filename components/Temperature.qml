import QtQuick
import QtQuick.Layouts

import qs
import qs.core as Core

RowLayout {
    id: root

    property string value: ""
    property string unit: Core.WeatherParse.getTemperatureUnitLetter()
    property string fontFamily: Settings.labelFontFamily
    property real fontSize: Settings.labelFontSize
    property real verticalOffset: Settings.inducedVerticalOffset
    property string color: Settings.colors.fgMain

    readonly property real degreeUnitSpacing: root.unit === "K" ? 1.75 : -1.75
    readonly property real labelVerticalOffset:
        (degreeMetrics.ascent - labelMetrics.ascent) / 2

    spacing: 0

    Text {
        text: root.value
        color: root.color
        font.family: root.fontFamily
        font.pixelSize: root.fontSize

        Layout.topMargin: root.unit === "K"
            ? root.verticalOffset
            : -root.labelVerticalOffset + root.verticalOffset

        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        visible: root.unit !== "K"
        text: "º"
        color: root.color
        font.family: Settings.labelFontFamily
        font.pixelSize: Settings.iconFontSize

        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: root.unit
        color: root.color
        font.family: root.fontFamily
        font.pixelSize: root.fontSize

        Layout.leftMargin: root.degreeUnitSpacing
        Layout.topMargin: root.unit === "K"
            ? root.verticalOffset
            : -root.labelVerticalOffset + root.verticalOffset

        Layout.alignment: Qt.AlignVCenter
    }

    FontMetrics {
        id: labelMetrics

        font.family: root.fontFamily
        font.pixelSize: root.fontSize
    }

    FontMetrics {
        id: degreeMetrics

        font.family: Settings.labelFontFamily
        font.pixelSize: Settings.iconFontSize
    }
}