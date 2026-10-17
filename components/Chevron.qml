import QtQuick
import QtQuick.Shapes

import qs.core as Core

Item {
    id: root

    // ────── Appearance ──────
    required property int leftCap
    required property int rightCap
    required property color bgFill
    // Zero flattens the cap; one draws its full point or notch.
    property real leftCapProgress: 1
    property real rightCapProgress: 1
    property color outlineColor: "transparent"
    property real outlineWidth: -1

    property real contentLeftPadding: 0
    property real contentRightPadding: 0

    default property alias content: contentContainer.data

    // ────── Sizing ──────
    // Both implicit sizes are derived from the content, so a Chevron is
    // self-sizing anywhere: inside a Layout, a Row, or on its own. Height is
    // normally overridden by the bar (Layout.fillHeight), and the cap widths
    // scale with whatever height it ends up at.
    implicitWidth:
        contentContainer.implicitWidth
        + contentLeftPadding
        + contentRightPadding
        + Core.ChevronGeometry.calcCapBoundingBox(root.height, root.leftCap, root.leftCapProgress)
        + Core.ChevronGeometry.calcCapBoundingBox(root.height, root.rightCap, root.rightCapProgress)

    implicitHeight: contentContainer.implicitHeight

    // ────── Hit Testing ──────
    // Shape.FillContains makes contains() test the filled polygon instead of
    // the bounding box, so the angled caps are not clickable dead zones. Only
    // matters to callers that hit-test; it does not affect rendering.
    function containsPoint(x, y) {
        return shape.contains(Qt.point(x, y))
    }

    // ────── Geometry ──────
    Shape {
        id: shape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        containsMode: Shape.FillContains

        ShapePath {
            fillColor: root.bgFill
            strokeColor: root.outlineColor
            strokeWidth: root.outlineWidth // -1 disables stroking entirely
            joinStyle: ShapePath.MiterJoin

            PathPolyline {
                path: Core.ChevronGeometry.polygon(
                    root.width,
                    root.height,
                    root.leftCap,
                    root.rightCap,
                    root.leftCapProgress,
                    root.rightCapProgress
                )
            }
        }
    }

    // ────── Content ──────
    Row {
        id: contentContainer

        anchors.verticalCenter: parent.verticalCenter
        x: Core.ChevronGeometry.calcCapBoundingBox(root.height, root.leftCap, root.leftCapProgress)
            + root.contentLeftPadding
    }
}
