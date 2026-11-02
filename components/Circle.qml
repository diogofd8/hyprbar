import QtQuick

BackgroundRectangle {
    id: root

    required property real diameter
    property bool paintInForeground: true

    width: diameter
    height: diameter
    radius: diameter / 2

    backgroundScope.target: root.paintInForeground ? null : root.backgroundScope.findTarget(root)
    // Keep local paint below child content, including fallback without a surface.
    backgroundScope.paintZOffset: -root.z - 1
}
