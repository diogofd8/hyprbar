import QtQuick

import qs

Item {
    id: root

    property string value: ""
    property int padding: 0
    property real verticalOffset: Settings.inducedVerticalOffset

    property string fontFamily: Settings.labelFontFamily
    property real fontSize: Settings.labelFontSize

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