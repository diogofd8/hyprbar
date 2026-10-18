import QtQuick

import qs

// Only this item allocates a texture. Its descendants contain background paint;
// controls and foreground content stay in their original visual tree.
BackgroundTarget {
    id: root

    property real backgroundOpacity: Settings.colors.background.opacity
    property bool renderActive: root.visible && (root.Window.window?.visible ?? false)
    readonly property BackgroundTarget paintTarget: root
    sourceItem: root.parent
    coordinateItem: root

    opacity: root.backgroundOpacity
    layer.enabled: root.renderActive
}
