import QtQuick

import qs
import qs.components

Item {
    id: root

    // ────── Appearance ──────
    property string glyph: ""
    property string fontFamily: Settings.iconFontFamily
    property real glyphSize: Configuration.editButtonSize
    property color color: Settings.colors.fgMain

    property color backgroundColor: "transparent"
    property color hoverColor: Settings.colors.fgMain
    property real hoverOpacity: Settings.colors.hoverOpacity

    property real borderWidth: 0
    property color borderColor: Settings.colors.fgMain

    property real padding: 0
    property real buttonHeight: Math.max(glyphItem.implicitWidth,
        glyphItem.implicitHeight) + root.padding
    property real verticalOffset
    property bool useMetrics

    property bool rotateOnClick: false

    // ────── Interaction ──────
    signal leftClicked()
    signal rightClicked()

    readonly property bool isHovered: mouseArea.containsMouse

    // ────── Sizing ──────
    implicitWidth: root.buttonHeight
    implicitHeight: root.buttonHeight

    // ────── Background ──────
    Rectangle {
        anchors.fill: parent

        color: root.backgroundColor
        border.width: root.borderWidth
        border.color: root.borderColor
    }

    // ────── Glyph ──────
    Glyph {
        id: glyphItem

        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: root.glyphSize

        useMetrics: root.useMetrics
        verticalOffset: root.verticalOffset

        transformOrigin: Item.Center
    }

    // ────── Hover ──────
    Rectangle {
        anchors.fill: parent

        color: root.hoverColor
        opacity: root.hoverOpacity
        visible: root.isHovered
    }

    // ────── Animation ──────
    SequentialAnimation {
        id: clickRotation

        NumberAnimation {
            target: glyphItem
            property: "rotation"
            to: -45
            duration: 200
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: glyphItem
            property: "rotation"
            to: 0
            duration: 300
            easing.type: Easing.InOutCubic
        }
    }

    // ────── Mouse Events ──────
    MouseArea {
        id: mouseArea

        anchors.fill: parent

        enabled: root.enabled
        hoverEnabled: true

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (root.rotateOnClick)
                    clickRotation.restart()

                root.leftClicked()
            } else if (mouse.button === Qt.RightButton) {
                root.rightClicked()
            }
        }
    }
}
