import QtQuick

import qs

Item {
    id: root

    property string value: ""
    property int padding: 0
    property real verticalOffset: Settings.inducedVerticalOffset

    property string fontFamily: Settings.labelFontFamily
    property real fontSize: Settings.labelFontSize

    // We use this measure to set the width of the percentage indicator, so that it doesn't change size when the value changes
    // Maximum value is 100, so we need to measure 3 characters + the % sign, plus some padding
    width: 4 * fontMetrics.averageCharacterWidth + padding
    height: parent.height

    Row {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.verticalOffset

        spacing: 2

        Text {
            text: root.value
            color: Settings.colors.fgMain
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
        }

        Text {
            text: "%"
            color: Settings.colors.fgMain
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
        }
    }

    FontMetrics {
        id: fontMetrics

        font.family: root.fontFamily
        font.pixelSize: root.fontSize
    }
}