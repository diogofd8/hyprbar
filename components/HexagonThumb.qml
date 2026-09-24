import QtQuick
import QtQuick.Shapes

// Concentric regular hexagons rendered in one coordinate system. All paths
// share the exact same centre; only their mathematically related heights vary.
Item {
    id: root

    property real separation: 2
    property color separationColor: "transparent"
    property color fillColor: "transparent"
    property int colorAnimationDuration: 0

    property bool hovered: false
    property color hoverColor: "transparent"
    property real hoverOpacity: 0

    readonly property real innerHeight: Math.max(0,
        root.height - 2 * root.separation)
    readonly property color hoverOverlayColor: root.hovered
        ? Qt.rgba(root.hoverColor.r, root.hoverColor.g, root.hoverColor.b,
            root.hoverColor.a * root.hoverOpacity)
        : "transparent"

    implicitWidth: implicitHeight * 2 / Math.sqrt(3)
    implicitHeight: 16

    Behavior on separationColor {
        ColorAnimation {
            duration: root.colorAnimationDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on fillColor {
        ColorAnimation {
            duration: root.colorAnimationDuration
            easing.type: Easing.InOutCubic
        }
    }

    function polygon(hexHeight) {
        const centerX = root.width / 2
        const centerY = root.height / 2
        const halfHeight = hexHeight / 2
        const halfWidth = hexHeight / Math.sqrt(3)

        return [
            Qt.point(centerX - halfWidth, centerY),
            Qt.point(centerX - halfWidth / 2, centerY - halfHeight),
            Qt.point(centerX + halfWidth / 2, centerY - halfHeight),
            Qt.point(centerX + halfWidth, centerY),
            Qt.point(centerX + halfWidth / 2, centerY + halfHeight),
            Qt.point(centerX - halfWidth / 2, centerY + halfHeight),
            Qt.point(centerX - halfWidth, centerY)
        ]
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.separationColor
            strokeWidth: -1

            PathPolyline {
                path: root.polygon(root.height)
            }
        }

        ShapePath {
            fillColor: root.fillColor
            strokeWidth: -1

            PathPolyline {
                path: root.polygon(root.innerHeight)
            }
        }

        ShapePath {
            fillColor: root.hoverOverlayColor
            strokeWidth: -1

            PathPolyline {
                path: root.polygon(root.innerHeight)
            }
        }
    }
}
