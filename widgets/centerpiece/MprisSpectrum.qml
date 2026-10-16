import QtQuick

import qs
import qs.components

Item {
    id: root

    property real diameter: Configuration.mprisArtImgSz + Configuration.mprisArtCircumferenceMargin
    property real clipRatio: Configuration.mprisArtCircumferenceClipRatio
    property real ringWidth: Configuration.mprisArtCircumferenceWidth
    property color ringColor: Settings.colors.fgMain
    property color barColor: Settings.colors.accentMain
    property int barCount: Configuration.mprisVisualizerBarCount
    property real barWidth: Configuration.mprisVisualizerBarWidth
    property real barHeight: Configuration.mprisVisualizerBarHeight
    property real barDistance: Configuration.mprisVisualizerBarDistance

    // The audio source supplies normalized amplitudes; an empty frame is silent.
    property var levels: []

    readonly property real clippedRatio: Math.max(0, Math.min(0.5, root.clipRatio))
    readonly property real halfArcAngle: Math.asin(1 - 2 * root.clippedRatio) * 180 / Math.PI
    readonly property real barRadius: root.diameter / 2 + Math.max(0, root.barDistance)

    implicitWidth: root.visualDiameter()
    implicitHeight: implicitWidth

    Item {
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        width: root.diameter
        height: width * (1 - 2 * root.clippedRatio)
        clip: true

        Circle {
            id: mprisCircumference
            anchors.centerIn: parent
            anchors.alignWhenCentered: false
            diameter: root.diameter
            color: "transparent"
            border.width: root.ringWidth
            border.color: root.ringColor
        }
    }

    Repeater {
        model: root.halfArcAngle > 0 ? Math.max(0, root.barCount) : 0

        delegate: Item {
            required property int index
            anchors.centerIn: parent
            anchors.alignWhenCentered: false
            width: root.width
            height: root.height
            rotation: root.barAngle(index)

            Rectangle {
                x: (parent.width - width) / 2
                y: parent.height / 2 - root.barRadius - height
                width: Math.max(0, root.barWidth)
                height: Math.max(0, root.barHeight) * root.barLevel(index)
                radius: width / 2
                color: root.barColor
                antialiasing: true
            }
        }
    }

    function visualDiameter(): real {
        const extent = Math.max(0, root.barDistance) + Math.max(0, root.barHeight)
        return root.diameter + 2 * extent + Math.max(0, root.barWidth)
    }

    function barAngle(index: int): real {
        // Without clipping, distribute around the complete circle so the two
        // arcs don't create duplicate bars at the top and bottom.
        if (root.clippedRatio === 0)
            return index * 360 / Math.max(1, root.barCount)

        const rightCount = Math.ceil(root.barCount / 2)
        const rightSide = index < rightCount
        const count = rightSide ? rightCount : root.barCount - rightCount
        const offset = rightSide ? index : index - rightCount
        const centerAngle = rightSide ? 90 : 270
        if (count <= 1)
            return centerAngle
        return centerAngle - root.halfArcAngle + offset * 2 * root.halfArcAngle / (count - 1)
    }

    function barLevel(index: int): real {
        const levels = root.levels ?? []
        const level = levels.length ? Number(levels[index % levels.length]) : 0
        return Number.isFinite(level) ? Math.sqrt(Math.max(0, Math.min(1, level))) : 0
    }
}
