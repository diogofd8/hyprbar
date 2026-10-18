import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components

import "centerpiece" as CenterPieceUI

// One popup shell with independent pages. The selected page is the only
// one instantiated; services that must outlive the popup belong in core/.
Pane {
    id: root

    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }

    readonly property var tabs: CenterPieceUI.Configuration.tabs
    property int activeTab: root.tabs.findIndex(tab => tab.key === "weather")

    implicitWidth: CenterPieceUI.Configuration.widgetWidth
    implicitHeight: CenterPieceUI.Configuration.widgetHeight
    padding: WidgetConfiguration.dropDownWindowPadding
    clip: true
    background: null

    contentItem: RowLayout {
        spacing: 0 // selector & content gap

        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.topMargin: CenterPieceUI.Configuration.tabButtonSpacing
            Layout.bottomMargin: CenterPieceUI.Configuration.tabButtonSpacing
            spacing: CenterPieceUI.Configuration.tabButtonSpacing
            uniformCellSizes: true

            Repeater {
                model: root.tabs

                delegate: RowLayout {
                    id: tabEntry

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: CenterPieceUI.Configuration.tabSelectorSpacing

                    required property int index
                    required property var modelData

                    GlyphButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignCenter

                        contentLeftPadding: CenterPieceUI.Configuration.tabIconPaddingX
                        contentRightPadding: CenterPieceUI.Configuration.tabIconPaddingX

                        icon: tabEntry.modelData.icon
                        iconSize: WidgetConfiguration.widgetMainIconSz
                        useMetrics: true

                        onLeftClicked: root.activeTab = tabEntry.index
                    }

                    Separator {
                        Layout.fillHeight: true
                        orientation: Qt.Vertical
                        thickness: CenterPieceUI.Configuration.tabSelectorWidth
                        color: Settings.colors.background.accent

                        opacity: root.activeTab === tabEntry.index ? 1 : 0
                    }
                }
            }
        }

        Separator {
            Layout.fillHeight: true
            orientation: Qt.Vertical
            color: Settings.colors.background.tint2
            opacity: Settings.colors.background.dimOpacity
        }

        Loader {
            id: backgroundClip2
            readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: backgroundClip2 }

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            source: root.tabs[root.activeTab]?.source ?? ""
        }
    }
}
