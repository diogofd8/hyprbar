import QtQuick

Item {
    id: root

    property color color
    property int orientation: Qt.Horizontal
    // Logical thickness, rounded up to whole device pixels
    property real thickness: 1

    readonly property real dpr: root.Window.window ? root.Window.window.devicePixelRatio : 1
    // Fractional scaling can put the computed thickness just above a whole
    // device pixel; tolerate that small overshoot before rounding up.
    readonly property real devicePixelRoundingTolerance: 0.01
    readonly property int devicePixels: Math.max(1,
        Math.ceil(root.thickness * root.dpr - root.devicePixelRoundingTolerance))

    // Align the thickness axis to the window's device-pixel grid.
    readonly property real windowPosition: {
        let position = 0
        for (let item = root; item; item = item.parent)
            position += root.orientation === Qt.Vertical ? item.x : item.y
        return position
    }
    readonly property real alignedOffset:
        Math.round(root.windowPosition * root.dpr) / root.dpr - root.windowPosition

    implicitWidth: root.orientation === Qt.Vertical ? root.thickness : 0
    implicitHeight: root.orientation === Qt.Horizontal ? root.thickness : 0

    BackgroundRectangle {
        x: root.orientation === Qt.Vertical ? root.alignedOffset : 0
        y: root.orientation === Qt.Horizontal ? root.alignedOffset : 0
        width: root.orientation === Qt.Vertical ? root.devicePixels / root.dpr : parent.width
        height: root.orientation === Qt.Vertical ? parent.height : root.devicePixels / root.dpr
        color: root.color
    }
}
