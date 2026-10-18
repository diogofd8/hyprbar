import QtQuick

import qs
import qs.components

Item {
    id: root

    property Item backgroundTarget: null
    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }

    // ────── Appearance ──────
    property color bgFill: Settings.colors.background.tint1
    property color inactiveColor: Settings.colors.background.highlight
    property color activeColor: Settings.colors.background.accent
    property color hoverColor: Settings.colors.background.highlight
    property real hoverOpacity: Settings.colors.background.hoverOpacity

    property real trackWidth: 18
    property real trackHeight: 5
    property real trackOutlineWidth: 2
    property real thumbHeight: 14
    property real thumbSeparation: 1
    property int transitionDuration: 400

    readonly property real thumbWidth: root.thumbHeight * 2 / Math.sqrt(3)
    readonly property real centerY: root.height / 2
    readonly property real leftThumbCenterX: root.thumbWidth / 2
    readonly property real rightThumbCenterX: root.leftThumbCenterX + root.trackWidth
    readonly property color switchColor: root.checked ? root.activeColor : root.inactiveColor

    // ────── Component Input ──────
    required property bool actionable
    required property bool checked
    signal clicked()

    // The track spans between the two possible thumb centres. The component
    // bounds add half a thumb on each end and use the taller thumb for height.
    implicitWidth: root.trackWidth + root.thumbWidth
    implicitHeight: root.thumbHeight

    // ────── Toggle ──────
    Item {
        id: toggle

        anchors.fill: parent

        Hexagon {
            id: track

            x: root.leftThumbCenterX
            y: root.centerY - height / 2
            width: root.trackWidth
            height: root.trackHeight

            fillColor: root.bgFill
            outlineColor: root.switchColor
            outlineWidth: root.trackOutlineWidth
            colorAnimationDuration: root.transitionDuration

            hovered: trackMouseArea.containsMouse
                && !thumbMouseArea.containsMouse
            hoverColor: root.hoverColor
            hoverOpacity: root.hoverOpacity
        }

        HexagonThumb {
            id: thumb
            z: 1

            property real centerX: root.checked
                ? root.rightThumbCenterX : root.leftThumbCenterX

            x: centerX - width / 2
            y: root.centerY - height / 2
            width: root.thumbWidth
            height: root.thumbHeight

            separation: root.thumbSeparation
            separationColor: root.bgFill
            fillColor: root.switchColor
            colorAnimationDuration: root.transitionDuration

            hovered: thumbMouseArea.containsMouse
            hoverColor: root.hoverColor
            hoverOpacity: root.hoverOpacity

            Behavior on centerX {
                NumberAnimation {
                    duration: root.transitionDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    // ────── Mouse Areas ──────
    Item {
        id: mouseAreas

        anchors.fill: parent

        MouseArea {
            id: trackMouseArea

            x: track.x
            y: track.y
            width: track.width
            height: track.height

            enabled: root.actionable
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: root.clicked()
        }

        MouseArea {
            id: thumbMouseArea

            x: thumb.x
            y: thumb.y
            width: thumb.width
            height: thumb.height

            enabled: root.actionable
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: root.clicked()
        }
    }
}
