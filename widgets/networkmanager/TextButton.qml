import QtQuick

import qs

Item {
    id: root

    // ────── Appearance ──────
    property string text: ""
    property string fontFamily: Settings.labelFontFamily
    property real fontSize: Configuration.textButtonFontSize
    property color color: Settings.colors.fgMain

    property color backgroundColor: "transparent"
    property color hoverColor: Settings.colors.fgMain
    property real hoverOpacity: Settings.colors.hoverOpacity

    property real borderWidth: 1
    property color borderColor: Settings.colors.fgMain

    property real paddingX: 0
    property real paddingY: 0

    // ────── Interaction ──────
    signal leftClicked()
    signal rightClicked()

    readonly property bool isHovered: mouseArea.containsMouse

    // ────── Sizing ──────
    implicitWidth: textItem.implicitWidth + root.paddingX
    implicitHeight: textItem.implicitHeight + root.paddingY

    // ────── Background ──────
    Rectangle {
        anchors.fill: parent

        color: root.backgroundColor
        border.width: root.borderWidth
        border.color: root.borderColor
    }

    // ────── Content ──────
    Text {
        id: textItem

        anchors.centerIn: parent
        text: root.text
        color: root.color
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
    }

    // ────── Hover ──────
    Rectangle {
        anchors.fill: parent

        color: root.hoverColor
        opacity: root.hoverOpacity
        visible: root.isHovered
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
            if (mouse.button === Qt.LeftButton)
                root.leftClicked()
            else if (mouse.button === Qt.RightButton)
                root.rightClicked()
        }
    }
}
