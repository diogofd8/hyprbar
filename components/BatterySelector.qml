import QtQuick

import qs
import qs.components

Circle {
    required property color dotColor
    required property color dotBgColor

    diameter: 6
    border.width: 1
    border.color: dotBgColor
    color: dotColor

    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: -2
    anchors.bottomMargin: 2
}