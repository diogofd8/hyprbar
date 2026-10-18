import QtQuick
import QtQuick.Layouts

import qs

RowLayout {
    id: root

    required property real value
    required property string unit
    required property int decimals
    required property real unitSpacingRatio

    property string unknownText: "N/A"
    property string fontFamily: Settings.labelFontFamily
    property real fontSize: Settings.labelFontSize
    property color color: Settings.colors.foreground.main

    spacing: root.fontSize * root.unitSpacingRatio

    Text {
        text: root.valueText()
        color: root.color
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
    }

    Text {
        text: root.unit
        color: root.color
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
    }

    // ────── Helper Functions ──────
    function valueText(): string {
        return Number.isFinite(root.value) ? root.value.toFixed(root.decimals) : root.unknownText
    }
}
