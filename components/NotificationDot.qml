import QtQuick

import qs
import qs.components

Circle {
    required property color dotColor
    required property color dotBgColor
    property bool leftAlign: false
    property bool topAlign: false
    property real displacementX: -2
    property real displacementY: 2

    diameter: 6
    border.width: 1
    border.color: dotBgColor
    color: dotColor

    anchors.left: leftAlign ? parent.left : undefined
    anchors.right: leftAlign ? undefined : parent.right
    anchors.top: topAlign ? parent.top : undefined
    anchors.bottom: topAlign ? undefined : parent.bottom

    anchors.leftMargin: leftAlign ? displacementX : 0
    anchors.rightMargin: leftAlign ? 0 : displacementX
    anchors.topMargin: topAlign ? displacementY : 0
    anchors.bottomMargin: topAlign ? 0 : displacementY
}
