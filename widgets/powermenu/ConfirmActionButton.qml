import QtQuick
import QtQuick.Controls as Controls

import qs
import qs.components

Controls.AbstractButton {
    id: root

    required property Chevron container
    required property string glyph
    property color bgFill: "transparent"
    property color glyphColor: Settings.colors.fgMain
    property int glyphSize: Configuration.confirmActionIconSz

    padding: 0
    leftPadding: Configuration.confirmActionBtnLeftPadding
    rightPadding: Configuration.confirmActionBtnRightPadding
    hoverEnabled: true
    contentItem: Item {
        Glyph {
            id: glyphItem

            icon: root.glyph
            iconColor: root.glyphColor
            iconSize: root.glyphSize
            useMetrics: false
            x: root.glyphX()
            y: root.glyphY()
        }

        TextMetrics {
            id: glyphMetrics
            font: glyphItem.font
            text: glyphItem.icon
        }
    }

    HoverHandler {
        cursorShape: root.hovered ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    Keys.onReturnPressed: event => {
        if (!event.isAutoRepeat)
            root.clicked()
    }
    Keys.onEnterPressed: event => {
        if (!event.isAutoRepeat)
            root.clicked()
    }
    Keys.onSpacePressed: event => event.accepted = true

    // Exclude the chevron's empty corners from this button's input area.
    containmentMask: QtObject {
        function contains(position: point): bool {
            if (position.x < 0 || position.x >= root.width
                    || position.y < 0 || position.y >= root.height)
                return false
            const mapped = root.mapToItem(root.container, position)
            return root.container.containsPoint(mapped.x, mapped.y)
        }
    }

    background: Item {
        clip: true

        // Paint the full chevron, cropped to this button's slice of the column.
        Chevron {
            width: root.container.width
            height: root.container.height
            y: -root.y
            leftCap: root.container.leftCap
            rightCap: root.container.rightCap
            bgFill: root.buttonColor()
        }
    }

    function glyphX(): real {
        const bounds = glyphMetrics.tightBoundingRect
        return root.contentItem.width / 2 - bounds.x - bounds.width / 2
    }

    function glyphY(): real {
        const bounds = glyphMetrics.tightBoundingRect
        return root.height / 2 - root.contentItem.y
            - glyphItem.baselineOffset - bounds.y - bounds.height / 2
    }

    function buttonColor(): color {
        if (!root.hovered && !root.down && !root.activeFocus)
            return root.bgFill
        const tint = Settings.colors.fgMain
        const opacity = root.down || root.activeFocus
            ? Settings.colors.hoverOpacityStrong : Settings.colors.hoverOpacity
        return Qt.tint(root.bgFill, Qt.rgba(tint.r, tint.g, tint.b, opacity))
    }
}
