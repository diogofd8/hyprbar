import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Shapes

import qs

// One colour channel: a gradient track under a hexagonal colour sample. A
// slightly larger hexagon is cut out of the track around the sample, so the
// widget background itself shows through as the sample's border.
Slider {
    id: root

    property Gradient trackGradient: null
    property color thumbColor: "transparent"

    property real trackWidth: 300
    property real trackHeight: 8
    property real thumbHeight: 16
    property real thumbGap: 2
    readonly property real thumbWidth: root.thumbHeight * 2 / Math.sqrt(3)
    readonly property real trackLength: Math.max(0, root.availableWidth - root.thumbWidth)

    stepSize: 1
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitWidth: root.trackWidth + root.thumbWidth
    implicitHeight: Math.max(root.trackHeight, root.thumbHeight)

    background: Item {
        x: root.leftPadding + root.thumbWidth / 2
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.trackLength
        height: root.trackHeight

        Rectangle {
            id: track
            anchors.fill: parent
            radius: height / 2
            gradient: root.trackGradient
            transform: Scale { origin.x: track.width / 2; xScale: root.mirrored ? -1 : 1 }
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskInverted: true
                maskSource: gap
            }
        }

        // The mask is sampled before the mirroring transform, so it follows
        // the logical position rather than the visual one.
        Item {
            id: gap
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true

            // A plain Shape: HexagonThumb's projected paint copies this hidden
            // item's visibility and would leave the mask empty.
            Shape {
                id: gapShape
                height: root.thumbHeight + 2 * root.thumbGap
                width: height * 2 / Math.sqrt(3)
                x: root.position * gap.width - width / 2
                y: (gap.height - height) / 2
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "#FFFFFF"
                    strokeWidth: -1
                    PathPolyline {
                        path: {
                            const w = gapShape.width, h = gapShape.height
                            return [Qt.point(0, h / 2), Qt.point(w / 4, 0), Qt.point(3 * w / 4, 0),
                                Qt.point(w, h / 2), Qt.point(3 * w / 4, h), Qt.point(w / 4, h), Qt.point(0, h / 2)]
                        }
                    }
                }
            }
        }
    }

    handle: Item {
        x: root.leftPadding + root.visualPosition * root.trackLength
        y: root.topPadding + (root.availableHeight - height) / 2
        implicitWidth: root.thumbWidth
        implicitHeight: root.thumbHeight

        HexagonThumb {
            anchors.fill: parent
            // Keep the colour sample opaque, above the composited background.
            backgroundScope.target: null
            // Keyboard focus outlines the sample; the cut-out is the usual border.
            separation: root.visualFocus ? 1.5 : 0
            separationColor: Settings.colors.foreground.main
            fillColor: root.thumbColor
            hovered: root.hovered || root.pressed
            hoverColor: "#FFFFFF"
            hoverOpacity: 0.08
        }

        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
}
