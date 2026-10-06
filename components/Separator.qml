import QtQuick

Item {
    id: root

    property color color
    // Logical thickness, rounded up to whole device pixels
    property real thickness: 1

    readonly property real dpr: root.Window.window ? root.Window.window.devicePixelRatio : 1
    // Fractional scaling can put the computed thickness just above a whole
    // device pixel; tolerate that small overshoot before rounding up.
    readonly property real devicePixelRoundingTolerance: 0.01
    readonly property int devicePixels: Math.max(1,
        Math.ceil(root.thickness * root.dpr - root.devicePixelRoundingTolerance))

    readonly property real windowY: {
        let y = 0
        for (let item = root; item; item = item.parent)
            y += item.y
        return y
    }

    implicitHeight: root.thickness

    Rectangle {
        y: Math.round(root.windowY * root.dpr) / root.dpr - root.windowY
        width: parent.width
        height: root.devicePixels / root.dpr
        color: root.color
    }
}
