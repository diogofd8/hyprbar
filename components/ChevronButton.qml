import QtQuick

import qs

Item {
    id: root

    // ────── Chevron Passthrough ──────
    // Mirrors Chevron's own API, so a display Chevron can be swapped for an
    // interactive one without changing anything else at the call site.
    required property int leftCap
    required property int rightCap
    required property color bgFill
    property color hoverColor: Settings.colors.fgMain
    property real hoverOpacity: Settings.colors.hoverOpacity

    property real contentLeftPadding: 0
    property real contentRightPadding: 0

    default property alias content: chevron.content

    // ────── Interaction ──────
    // Signals rather than one `action` property: a button carries only the
    // gestures it actually uses, and an unconnected signal is simply ignored,
    // so nothing has to be declared just to satisfy the component.
    signal leftClicked()
    signal rightClicked()

    // +1 per notch up, -1 per notch down, already normalised.
    signal scrolled(int steps)

    // True only while the cursor is over the chevron's filled shape, never
    // over the dead corners its angled caps cut out of the bounding box.
    // The size terms are not redundant: they re-evaluate this when the
    // chevron resizes under a cursor that has not moved.
    readonly property bool hovered:
        mouseArea.containsMouse
        && chevron.width > 0
        && chevron.height > 0
        && chevron.containsPoint(mouseArea.mouseX, mouseArea.mouseY)

    // ────── Sizing ──────
    // Deferred to the chevron so the button self-sizes exactly like the
    // Chevron it stands in for.
    implicitWidth: chevron.implicitWidth
    implicitHeight: chevron.implicitHeight

    Chevron {
        id: chevron

        anchors.fill: parent

        leftCap: root.leftCap
        rightCap: root.rightCap
        bgFill: root.bgFill

        contentLeftPadding: root.contentLeftPadding
        contentRightPadding: root.contentRightPadding
    }

    // Hover tint, drawn as a separate shape so it composites over whatever
    // the chevron itself sits on rather than over a colour assumed here.
    Chevron {
        anchors.fill: parent

        leftCap: root.leftCap
        rightCap: root.rightCap

        bgFill: root.hoverColor
        opacity: root.hoverOpacity
        visible: root.hovered
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

        // A MouseArea can only be rectangular, so presses landing in the cap
        // corners are handed back to whatever is underneath — chevrons in a
        // row overlap by a full cap width.
        propagateComposedEvents: true

        onPressed: mouse => mouse.accepted = root.hovered

        onClicked: mouse => {
            if (!root.hovered)
                return

            if (mouse.button === Qt.RightButton)
                root.rightClicked()
            else
                root.leftClicked()
        }

        onWheel: wheel => {
            if (!root.hovered) {
                wheel.accepted = false
                return
            }

            scroll.accumulate(wheel.angleDelta.y)
        }
    }
}
