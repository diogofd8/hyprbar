import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Quickshell.Services.SystemTray as TrayService

import qs
import qs.components
import qs.core as Core

import "systemtray" as SysTrayUI

Pane {
    id: root
    signal dismissRequested()
    signal platformMenuOpened()
    signal platformMenuClosed()

    readonly property string panelBackgroundColor: Settings.colors.bgMain
    readonly property real targetImplicitHeight: panelContent.implicitHeight + root.topPadding + root.bottomPadding
    readonly property var visibleItems: TrayService.SystemTray.items.values.filter(
        item => SysTrayUI.Configuration.isVisible(item)
    )
    readonly property bool isEmpty: root.visibleItems.length === 0

    padding: SysTrayUI.Configuration.widgetBoxPadding
    implicitHeight: root.targetImplicitHeight
    clip: true

    background: Rectangle {
        color: Qt.alpha(root.panelBackgroundColor, Settings.colors.bgOpacity)

        border.width: 1
        border.color: Qt.alpha(Settings.colors.fgMain, Settings.colors.hoverOpacity)

        // Hide the top border
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: parent.border.width
            color: root.panelBackgroundColor
        }
    }

    contentItem: RowLayout {
        id: panelContent

        Text {
            Layout.fillWidth: true
            visible: root.visibleItems.length === 0

            text: "EMPTY TRAY"
            color: Settings.colors.fgMain
            font.family: Settings.labelFontFamily
            font.pixelSize: Settings.smallCapsFontSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: 0.7
        }

        RowLayout {
            id: itemsRow

            Layout.fillWidth: true
            spacing: SysTrayUI.Configuration.stEntryRowSpacing
            visible: root.visibleItems.length > 0

            Repeater {
                model: TrayService.SystemTray.items

                delegate: SysTrayUI.TrayEntry {
                    required property var modelData

                    trayItem: modelData
                    visible: SysTrayUI.Configuration.isVisible(trayItem)

                    onMenuAboutToOpen: root.platformMenuOpened()
                    onMenuClosed: root.platformMenuClosed()
                }
            }
        }
    }

}
