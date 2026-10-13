import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    // ────── Appearance ──────
    property alias strokeWidth: outline.strokeWidth
    property alias strokeColor: outline.strokeColor
    property alias capStyle: outline.capStyle
    // Insets on each side: width is horizontal, height is vertical.
    property size innerPadding: Qt.size(0, 0)

    // ────── Countdown ──────
    // Milliseconds; deadline is an absolute timestamp, or zero to reset.
    property int duration: 0
    property double deadline: 0
    property real remaining: 1

    anchors.alignWhenCentered: false
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: outline

        fillColor: "transparent"
        strokeWidth: 2
        strokeColor: "white"
        capStyle: ShapePath.FlatCap

        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: Math.max(0, (root.width - outline.strokeWidth) / 2 - root.innerPadding.width)
            radiusY: Math.max(0, (root.height - outline.strokeWidth) / 2 - root.innerPadding.height)
            startAngle: -90 + 360 * (1 - root.remaining)
            sweepAngle: 360 * root.remaining
        }
    }

    NumberAnimation {
        id: countdownAnimation

        target: root
        property: "remaining"
        to: 0
        easing.type: Easing.Linear
    }

    onDurationChanged: syncCountdown()
    onDeadlineChanged: syncCountdown()
    onVisibleChanged: syncCountdown()
    Component.onCompleted: syncCountdown()

    function syncCountdown(): void {
        countdownAnimation.stop()
        if (root.duration <= 0 || root.deadline <= 0) {
            root.remaining = 1
            return
        }

        const remainingMs = Math.max(0, root.deadline - Date.now())
        root.remaining = Math.min(1, remainingMs / root.duration)

        if (root.visible && remainingMs > 0) {
            countdownAnimation.duration = remainingMs
            countdownAnimation.start()
        }
    }
}
