import QtQuick
import QtQuick.Controls.Basic

import qs
import qs.components

Slider {
    id: root

    property Item backgroundTarget: null
    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }

    // ────── Appearance ──────
    property color bgFill: Settings.colors.background.tint1
    property color inactiveColor: Settings.colors.background.highlight
    property color activeColor: Settings.colors.background.accent
    property color hoverColor: Settings.colors.background.highlight
    property real hoverOpacity: Settings.colors.background.hoverOpacity
    property real dimOpacity: Settings.colors.foreground.dimOpacity

    // Preferred track length only; the actual track follows the assigned width.
    property real trackWidth: 100
    property real trackHeight: 2
    property real activeTrackHeight: root.trackHeight + 1
    property real thumbHeight: 10
    property real thumbSeparation: 1
    property real tickHeight: 4
    property int transitionDuration: 150

    property int stepCount: 3
    readonly property int effectiveStepCount: Math.max(2, stepCount)
    readonly property real thumbWidth: root.thumbHeight * 2 / Math.sqrt(3)
    readonly property real trackLength: Math.max(0, root.availableWidth - root.thumbWidth)
    readonly property real centerY: root.topPadding + root.availableHeight / 2

    // ────── Component Input ──────
    property bool actionable: true

    enabled: root.actionable
    hoverEnabled: true
    padding: 0
    from: 0
    to: root.effectiveStepCount - 1
    stepSize: 1
    snapMode: Slider.SnapAlways

    implicitWidth: root.trackWidth + root.thumbWidth
    implicitHeight: Math.max(root.trackHeight, root.activeTrackHeight,
        root.thumbHeight, root.tickHeight)

    // ────── Track ──────
    background: Item {
        id: trackContainer
        readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: trackContainer }

        x: root.leftPadding + root.thumbWidth / 2
        y: root.topPadding
        width: root.trackLength
        height: root.availableHeight

        readonly property real splitX: width * root.visualPosition
        readonly property color hoverOverlayColor: root.hovered && !thumbHover.hovered && !root.pressed
            ? Qt.rgba(root.hoverColor.r, root.hoverColor.g, root.hoverColor.b,
                root.hoverColor.a * root.hoverOpacity)
            : "transparent"

        // Plain rectangles keep the horizontal edges uniform at fractional
        // scales. The two sections meet underneath the hexagonal thumb.
        BackgroundRectangle {
            id: inactiveTrack

            x: root.mirrored ? 0 : trackContainer.splitX
            anchors.verticalCenter: parent.verticalCenter
            anchors.alignWhenCentered: false
            width: root.mirrored ? trackContainer.splitX : trackContainer.width - x
            height: root.trackHeight
            color: root.inactiveColor
            antialiasing: true

            Behavior on color {
                ColorAnimation {
                    duration: root.transitionDuration
                    easing.type: Easing.InOutCubic
                }
            }

            BackgroundRectangle {
                anchors.fill: parent
                color: trackContainer.hoverOverlayColor
            }
        }

        BackgroundRectangle {
            id: activeTrack

            x: root.mirrored ? trackContainer.splitX : 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.alignWhenCentered: false
            width: root.mirrored ? trackContainer.width - x : trackContainer.splitX
            height: root.activeTrackHeight
            color: root.activeColor
            antialiasing: true

            Behavior on color {
                ColorAnimation {
                    duration: root.transitionDuration
                    easing.type: Easing.InOutCubic
                }
            }

            BackgroundRectangle {
                anchors.fill: parent
                color: trackContainer.hoverOverlayColor
            }
        }

        // Ticks follow the track in paint order, while the handle is drawn
        // above the background. Keep centering subpixel-accurate at fractional
        // display scales, just like the horizontal track rectangles.
        Repeater {
            model: root.effectiveStepCount

            delegate: BackgroundRectangle {
                required property int index
                opacity: root.dimOpacity

                width: 2
                height: root.tickHeight
                x: root.calcStepLocation(index, width)
                anchors.verticalCenter: parent.verticalCenter
                anchors.alignWhenCentered: false
                color: root.inactiveColor
            }
        }
    }

    // ────── Thumb ──────
    handle: Item {
        id: thumb
        readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: thumb }
        implicitWidth: root.thumbWidth
        implicitHeight: root.thumbHeight
        width: implicitWidth
        height: implicitHeight

        x: root.leftPadding + root.visualPosition * root.trackLength
        y: root.centerY - height / 2

        // Same-size hexagon offset towards the unfilled track. It masks that
        // track without leaving a border around the filled side of the thumb.
        HexagonThumb {
            x: root.mirrored ? -root.thumbSeparation : root.thumbSeparation
            width: parent.width
            height: parent.height

            separation: 0
            fillColor: root.bgFill
        }

        HexagonThumb {
            z: 1
            anchors.fill: parent

            separation: 0
            fillColor: root.activeColor
            colorAnimationDuration: root.transitionDuration

            hovered: thumbHover.hovered || root.pressed
            hoverColor: root.hoverColor
            hoverOpacity: root.hoverOpacity
        }

        HoverHandler {
            id: thumbHover
            enabled: root.enabled
            cursorShape: Qt.PointingHandCursor
        }
    }

    function calcStepLocation(stepIndex, tickWidth) {
        const stepSpacing = root.trackLength / (root.effectiveStepCount - 1);
        const stepCenter = stepSpacing * stepIndex;
        return stepCenter - tickWidth / 2;
    }
}
