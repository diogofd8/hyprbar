import QtQuick

import qs

Text {
    id: root

    property bool useMetrics: true
    property real verticalOffset: -Settings.inducedVerticalOffset
    property alias icon: root.text
    property int iconSize: Settings.iconFontSize
    property color iconColor: Settings.colors.fgMain

    readonly property real inkCentre:
        lineMetrics.ascent
        + inkMetrics.tightBoundingRect.y
        + inkMetrics.tightBoundingRect.height / 2

    width: useMetrics ? lineMetrics.averageCharacterWidth : implicitWidth

    y: parent
        ? parent.height / 2 - inkCentre + root.verticalOffset
        : root.verticalOffset

    color: root.iconColor
    font.pixelSize: root.iconSize
    font.family: Settings.iconFontFamily

    horizontalAlignment: Text.AlignHCenter

    FontMetrics {
        id: lineMetrics

        font: root.font
    }

    TextMetrics {
        id: inkMetrics

        font: root.font
        text: root.icon
    }
}