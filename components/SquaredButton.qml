import QtQuick

import qs
import qs.components

Item {
    id: root

    property Item backgroundTarget: null
    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }

    // ────── Appearance ──────
    property string glyph: ""
    property string fontFamily: Settings.iconFontFamily
    required property real glyphSize
    property color color: Settings.colors.foreground.main

    property color bgFill: "transparent"
    property color hoverColor: Settings.colors.background.highlight
    property real hoverOpacity: Settings.colors.background.hoverOpacity

    property real borderWidth: 0
    property color borderColor: Settings.colors.background.highlight

    property real padding: 0
    property real buttonHeight: Math.max(glyphItem.implicitWidth,
        glyphItem.implicitHeight) + root.padding
    property real verticalOffset
    property bool useMetrics
    property bool alignWhenCentered: true

    property bool rotateOnClick: false
    property alias glyphRotation: glyphItem.rotation

    // ────── Interaction ──────
    signal leftClicked()
    signal rightClicked()

    readonly property bool isHovered: mouseArea.containsMouse

    // ────── Sizing ──────
    implicitWidth: root.buttonHeight
    implicitHeight: root.buttonHeight

    // ────── Background ──────
    BackgroundRectangle {
        z: -1
        anchors.fill: parent

        color: root.bgFill
        border.width: root.borderWidth
        border.color: root.borderColor
    }

    // ────── Glyph ──────
    Glyph {
        id: glyphItem

        anchors.centerIn: parent
        anchors.alignWhenCentered: root.alignWhenCentered
        text: root.glyph
        font.pixelSize: root.glyphSize
        font.family: root.fontFamily

        useMetrics: root.useMetrics
        verticalOffset: root.verticalOffset

        transformOrigin: Item.Center
    }

    // ────── Hover ──────
    BackgroundRectangle {
        z: 1
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
            to: Motion.squaredButtonPressAngle
            duration: Motion.squaredButtonPressMs
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: glyphItem
            property: "rotation"
            to: 0
            duration: Motion.squaredButtonReleaseMs
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
