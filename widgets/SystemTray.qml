import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Quickshell.Services.SystemTray as TrayService

import qs

import "systemtray" as SysTrayUI

Pane {
    id: root
    signal dismissRequested()
    signal platformMenuOpened()
    signal platformMenuClosed()

    readonly property string panelBackgroundColor: Settings.colors.bgMain
    readonly property var visibleItems: TrayService.SystemTray.items.values.filter(
        item => SysTrayUI.Configuration.isVisible(item)
    )
    readonly property bool isEmpty: root.visibleItems.length === 0

    padding: WidgetConfiguration.dropDownWindowPadding
    implicitHeight: panelContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    // PopoutHost draws the panel background shared by every widget. Null, not
    // omitted, so the Controls style doesn't add a default one.
    background: null

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
            opacity: Settings.colors.dimOpacity
        }

        RowLayout {
            id: itemsRow

            Layout.fillWidth: true
            spacing: WidgetConfiguration.sectionContentVSpacing
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
