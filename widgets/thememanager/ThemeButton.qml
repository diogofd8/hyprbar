import QtQuick
import QtQuick.Controls.Basic

import qs
import qs.components
import qs.widgets
import qs.core as Core

Button {
    id: root

    property string glyph: ""
    property int glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
    // For symbols whose optical centre differs from their ink centre.
    property real glyphHorizontalOffset: 0
    property real glyphVerticalOffset: 0
    property bool selected: false
    property bool colorSample: false
    property color bgFill: selected ? Settings.colors.background.accent : Settings.colors.background.tint3
    readonly property color ink: selected || colorSample ? Core.Oklch.contrastInk(bgFill) : Settings.colors.foreground.main

    implicitHeight: WidgetConfiguration.widgetEmbeddedIconSz + 10
    implicitWidth: implicitHeight * 2 / Math.sqrt(3)
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity
    Accessible.name: text
    containmentMask: QtObject {
        function contains(point: point): bool { return shape.containsPoint(point.x, point.y) }
    }
    background: Hexagon {
        id: shape
        // The control owns its size; its decorative background must not feed
        // its implicit size back into the native Button's sizing calculation.
        implicitWidth: 0
        implicitHeight: 0
        fillColor: root.bgFill
        outlineColor: root.activeFocus ? Settings.colors.foreground.main : "transparent"
        outlineWidth: root.activeFocus ? 1 : -1
        hovered: root.hovered || root.down
        hoverColor: Settings.colors.foreground.main
        hoverOpacity: root.down ? 0.16 : 0.08
        // A colour sample must not inherit the panel's translucent background.
        backgroundScope.target: root.colorSample ? null : shape.backgroundScope.findTarget(shape)
    }
    contentItem: Item {
        Glyph {
            id: glyphItem
            // Glyph centres its painted bounds vertically. Do the same
            // horizontally: the advance width's side bearings can be asymmetric.
            x: parent.width / 2 - glyphMetrics.tightBoundingRect.x
                - glyphMetrics.tightBoundingRect.width / 2 + root.glyphHorizontalOffset
            icon: root.glyph
            iconSize: root.glyphSize
            iconColor: root.ink
            verticalOffset: root.glyphVerticalOffset
            useMetrics: false
        }
        TextMetrics {
            id: glyphMetrics
            font: glyphItem.font
            text: glyphItem.icon
        }
    }
    Keys.onReturnPressed: clicked()
}
