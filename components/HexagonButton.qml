import QtQuick

import qs

Item {
    id: root

    // ────── Appearance ──────
    property alias glyph: glyphItem.icon
    property alias glyphSize: glyphItem.iconSize
    property alias glyphColor: glyphItem.iconColor

    property alias bgFill: hexagon.fillColor
    property alias outlineColor: hexagon.outlineColor
    property alias outlineWidth: hexagon.outlineWidth
    property alias colorAnimationDuration: hexagon.colorAnimationDuration

    property color hoverColor: Settings.colors.fgMain
    property real hoverOpacity: Settings.colors.hoverOpacity

    property real paddingOffset: 0
    property real defaultPadding: 10
    readonly property real padding: defaultPadding + paddingOffset

    // Most glyphs need no correction because positioning uses their actual
    // painted bounds. These remain available for intentionally asymmetric
    // symbols whose optical centre differs from their ink centre.
    property real glyphHorizontalOffset: 0
    property real glyphVerticalOffset: 0

    // ────── Interaction ──────
    signal leftClicked()
    signal rightClicked()
    signal scrolled(int steps)

    readonly property bool hovered:
        root.enabled
        && mouseArea.containsMouse
        && hexagon.width > 0
        && hexagon.height > 0
        && hexagon.containsPoint(mouseArea.mouseX, mouseArea.mouseY)

    // A regular point-left/right hexagon is completely determined by its
    // height. The requested font size therefore controls the whole button.
    implicitHeight: glyphItem.iconSize + padding
    implicitWidth: implicitHeight * 2 / Math.sqrt(3)

    Hexagon {
        id: hexagon

        anchors.fill: parent
        hovered: root.hovered
        hoverColor: root.hoverColor
        hoverOpacity: root.hoverOpacity
    }

    Glyph {
        id: glyphItem

        // Glyph already centres its painted bounds vertically. Horizontal
        // placement applies the same rule using TextMetrics instead of the
        // font's advance width, whose side bearings can be asymmetric.
        x: root.width / 2
            - glyphMetrics.tightBoundingRect.x
            - glyphMetrics.tightBoundingRect.width / 2
            + root.glyphHorizontalOffset

        useMetrics: false
        verticalOffset: root.glyphVerticalOffset
    }

    TextMetrics {
        id: glyphMetrics

        font: glyphItem.font
        text: glyphItem.icon
    }

    ScrollAccumulator {
        id: scroll

        onStepped: steps => root.scrolled(steps)
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.hovered ? Qt.PointingHandCursor : Qt.ArrowCursor
        propagateComposedEvents: true

        // Hit-test input at the event position; hover is only visual state.
        onPressed: mouse => mouse.accepted = hexagon.containsPoint(mouse.x, mouse.y)

        onClicked: mouse => {
            if (!hexagon.containsPoint(mouse.x, mouse.y))
                return

            if (mouse.button === Qt.RightButton)
                root.rightClicked()
            else
                root.leftClicked()
        }

        onWheel: wheel => {
            if (!hexagon.containsPoint(wheel.x, wheel.y)) {
                wheel.accepted = false
                return
            }

            scroll.accumulate(wheel.angleDelta.y)
        }
    }
}
