import QtQuick
import QtQuick.Shapes

// A flat-topped hexagon with pointy left and right ends. When width is the
// regular-hexagon width for the chosen height, all six sides are equal. A
// larger width intentionally produces the elongated shape used by the switch
// track.
Item {
    id: root

    property color fillColor: "transparent"
    property color outlineColor: "transparent"
    property real outlineWidth: -1
    property int colorAnimationDuration: 0
    property bool hovered: false
    property color hoverColor: "transparent"
    property real hoverOpacity: 0

    readonly property real regularWidth: height * 2 / Math.sqrt(3)
    readonly property color hoverOverlayColor: root.hovered
        ? Qt.rgba(root.hoverColor.r, root.hoverColor.g, root.hoverColor.b,
            root.hoverColor.a * root.hoverOpacity)
        : "transparent"

    implicitWidth: regularWidth
    implicitHeight: 16

    Behavior on fillColor {
        ColorAnimation {
            duration: root.colorAnimationDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on outlineColor {
        ColorAnimation {
            duration: root.colorAnimationDuration
            easing.type: Easing.InOutCubic
        }
    }

    function containsPoint(x, y) {
        return shape.contains(Qt.point(x, y))
    }

    function polygon() {
        // For a point-left/right regular hexagon, the horizontal cap is
        // h / (2 * sqrt(3)). Keeping this cap fixed while widening the shape
        // produces the elongated, symmetrical track geometry.
        const cap = root.height / (2 * Math.sqrt(3))
        const middle = root.height / 2
        return [
            Qt.point(cap, 0),
            Qt.point(root.width - cap, 0),
            Qt.point(root.width, middle),
            Qt.point(root.width - cap, root.height),
            Qt.point(cap, root.height),
            Qt.point(0, middle),
            Qt.point(cap, 0)
        ]
    }

    Shape {
        id: shape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        containsMode: Shape.FillContains

        ShapePath {
            fillColor: root.fillColor
            strokeColor: root.outlineColor
            strokeWidth: root.outlineWidth
            joinStyle: ShapePath.MiterJoin

            PathPolyline {
                path: root.polygon()
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.hoverOverlayColor
            strokeWidth: root.outlineWidth
            joinStyle: ShapePath.MiterJoin

            PathPolyline {
                path: root.polygon()
            }
        }
    }
}
