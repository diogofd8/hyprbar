import QtQuick

import qs

Item {
    id: root

    property string value: ""
    property int padding: 0
    property real verticalOffset: Settings.inducedVerticalOffset

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
            font.family: Settings.labelFontFamily
            font.pixelSize: Settings.labelFontSize
        }

        Text {
            text: "%"
            color: Settings.colors.fgMain
            font.family: Settings.labelFontFamily
            font.pixelSize: Settings.labelFontSize
        }
    }

    FontMetrics {
        id: fontMetrics

        font.family: Settings.labelFontFamily
        font.pixelSize: Settings.labelFontSize
    }
}