import QtQuick

import qs

Item {
    id: root

    property Item backgroundTarget: null
    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }

    // ────── Chevron Passthrough ──────
    // Mirrors Chevron's own API, so a display Chevron can be swapped for an
    // interactive one without changing anything else at the call site.
    required property int leftCap
    required property int rightCap
    required property color bgFill
    property bool paintInForeground: false
    property real leftCapProgress: 1
    property real rightCapProgress: 1
    property color hoverColor: Settings.colors.background.highlight
    property real hoverOpacity: Settings.colors.background.hoverOpacity

    property real contentLeftPadding: 0
    property real contentRightPadding: 0

    default property alias content: chevron.content

    // ────── Interaction ──────
    // Signals rather than one `action` property: a button carries only the
    // gestures it actually uses, and an unconnected signal is simply ignored,
    // so nothing has to be declared just to satisfy the component.
    signal leftClicked()
    signal middleClicked()
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
        leftCapProgress: root.leftCapProgress
        rightCapProgress: root.rightCapProgress
        bgFill: root.bgFill
        paintInForeground: root.paintInForeground

        contentLeftPadding: root.contentLeftPadding
        contentRightPadding: root.contentRightPadding
    }

    // Hover tint, drawn as a separate shape so it composites over whatever
    // the chevron itself sits on rather than over a colour assumed here.
    Chevron {
        z: 1
        anchors.fill: parent

        leftCap: root.leftCap
        rightCap: root.rightCap
        leftCapProgress: root.leftCapProgress
        rightCapProgress: root.rightCapProgress

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
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.hovered ? Qt.PointingHandCursor : Qt.ArrowCursor

        // A MouseArea can only be rectangular, so presses landing in the cap
        // corners are handed back to whatever is underneath — chevrons in a
        // row overlap by a full cap width.
        propagateComposedEvents: true

        // Hit-test input at the event position; hover is only visual state.
        onPressed: mouse => mouse.accepted = chevron.containsPoint(mouse.x, mouse.y)

        onClicked: mouse => {
            if (!chevron.containsPoint(mouse.x, mouse.y))
                return

            switch (mouse.button) {
                case Qt.RightButton: { root.rightClicked(); return }
                case Qt.LeftButton: { root.leftClicked(); return }
                case Qt.MiddleButton: { root.middleClicked(); return }
                default: return
            }
        }

        onWheel: wheel => {
            if (!chevron.containsPoint(wheel.x, wheel.y)) {
                wheel.accepted = false
                return
            }

            scroll.accumulate(wheel.angleDelta.y)
        }
    }
}
