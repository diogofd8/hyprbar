import QtQuick

import Quickshell
import Quickshell.Widgets

import qs

Item {
    id: root

    required property var trayItem

    signal menuAboutToOpen()
    signal menuClosed()

    implicitWidth: Settings.iconFontSize + 2 * Configuration.stEntryPadding
    implicitHeight: Settings.iconFontSize + 2 * Configuration.stEntryPadding

    IconImage {
        anchors.centerIn: parent

        width: Settings.iconFontSize
        height: Settings.iconFontSize
        source: root.trayItem.icon
    }

    Rectangle {
        anchors.fill: parent

        color: Settings.colors.fgMain
        opacity: mouseArea.containsMouse ? Settings.colors.hoverOpacity : 0
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                root.trayItem.secondaryActivate()
            } else if (mouse.button === Qt.RightButton || root.trayItem.onlyMenu) {
                root.showMenu()
            } else {
                root.trayItem.activate()
            }
        }
    }

    QsMenuAnchor {
        id: menuAnchor

        menu: root.trayItem.menu

        anchor {
            window: root.QsWindow.window
        }

        onClosed: root.menuClosed()
    }

    function showMenu() {
        if (!root.trayItem.hasMenu)
            return

        if (!root.QsWindow.window)
            return

        menuAnchor.anchor.rect = root.QsWindow.itemRect(root)
        root.menuAboutToOpen()
        menuAnchor.open()
    }
}
