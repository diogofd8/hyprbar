import QtQuick

import qs

Item {
    id: root

    // ────── Glyph Passthrough ──────
    // Mirrors Glyph's own API, so a display Glyph can be swapped for an
    // interactive one without changing anything else at the call site.
    // Both spellings are kept because call sites use either `icon` or `text`.
    property alias icon: glyph.text
    property alias text: glyph.text
    property alias iconSize: glyph.iconSize
    property alias iconColor: glyph.iconColor
    property alias useMetrics: glyph.useMetrics
    property alias verticalOffset: glyph.verticalOffset
    property alias font: glyph.font

    property color hoverColor: Settings.colors.fgMain
    property real hoverOpacity: Settings.colors.hoverOpacity

    property real contentLeftPadding: 0
    property real contentRightPadding: 0

    // ────── Interaction ──────
    // Signals rather than one `action` property: a button carries only the
    // gestures it actually uses, and an unconnected signal is simply ignored,
    // so nothing has to be declared just to satisfy the component.
    signal leftClicked()
    signal rightClicked()

    // +1 per notch up, -1 per notch down, already normalised.
    signal scrolled(int steps)

    // The glyph fills the button's full height, so unlike a chevron there are
    // no dead corners to exclude — the bounding box is the shape.
    readonly property bool hovered: mouseArea.containsMouse

    // ────── Sizing ──────
    // Derived from the glyph so the button self-sizes exactly like the Glyph
    // it stands in for. Height is normally overridden by the bar
    // (Layout.fillHeight), which is what the hover fill stretches to.
    implicitWidth: glyph.width + contentLeftPadding + contentRightPadding
    implicitHeight: glyph.implicitHeight

    // Hover tint, drawn under the glyph so it composites over whatever the
    // button itself sits on rather than over a colour assumed here.
    Rectangle {
        anchors.fill: parent

        color: root.hoverColor
        opacity: root.hoverOpacity
        visible: root.hovered
    }

    // ────── Content ──────
    Glyph {
        id: glyph

        x: root.contentLeftPadding
    }

    ScrollAccumulator {
        id: scroll

        onStepped: steps => root.scrolled(steps)
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.hovered ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked()
            else
                root.leftClicked()
        }

        onWheel: wheel => scroll.accumulate(wheel.angleDelta.y)
    }
}
