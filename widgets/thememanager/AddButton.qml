import QtQuick
import QtQuick.Controls.Basic

import qs
import qs.components
import qs.widgets

// The slot that saves the current colour: a hollow, ringed hexagon the same
// size as a saved colour, whose plus turns while hovered.
Button {
    id: root

    // Not `highlighted`: that is a final AbstractButton property.
    readonly property bool hoverOrFocus: enabled && (hovered || visualFocus)
    readonly property color ink: hoverOrFocus ? Settings.colors.foreground.accent : Settings.colors.foreground.main

    implicitHeight: Configuration.colorBtnSz
    implicitWidth: implicitHeight * 2 / Math.sqrt(3)
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Settings.colors.foreground.dimOpacity
    Accessible.name: text

    containmentMask: QtObject {
        function contains(point: point): bool {
            const dy = Math.abs(point.y - root.height / 2)
            return dy <= root.height / 2 && Math.abs(point.x - root.width / 2) <= root.width / 2 - dy / Math.sqrt(3)
        }
    }

    background: Item {
        // The stroke is centred on its path, so the path runs through the
        // middle of the ring and the ring's outer edge meets the bounds.
        Hexagon {
            anchors.centerIn: parent
            anchors.alignWhenCentered: false
            height: parent.height - Configuration.addColorBorderSz
            width: regularWidth
            fillColor: root.hoverOrFocus
                ? Qt.alpha(Settings.colors.background.highlight, Settings.colors.background.hoverOpacity) : "transparent"
            outlineColor: root.ink
            outlineWidth: Configuration.addColorBorderSz
            // Opaque, above the composited background, like the colours beside it.
            backgroundScope.target: null
        }
    }

    contentItem: Item {
        rotation: root.hoverOrFocus ? Motion.themeAddColorHoverAngle : 0

        Behavior on rotation { Anim {} }

        Glyph {
            id: glyphItem
            // Centre the ink, rather than the font's advance box, so the
            // turning plus never orbits.
            x: parent.width / 2 - glyphMetrics.tightBoundingRect.x - glyphMetrics.tightBoundingRect.width / 2
            icon: Configuration.saveIcon
            iconSize: Configuration.btnsIconSz
            iconColor: root.ink
            verticalOffset: 0
            useMetrics: false
        }

        TextMetrics {
            id: glyphMetrics
            font: glyphItem.font
            text: glyphItem.icon
        }
    }

    Keys.onReturnPressed: clicked()
}
