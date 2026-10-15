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

    readonly property int calendarTab: 0
    readonly property int weatherTab: 1
    readonly property var tabs: CenterPieceUI.Configuration.tabs
    property int activeTab: weatherTab

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

                        icon: CenterPieceUI.Configuration.tabIcon[tabEntry.modelData.key]
                        iconSize: WidgetConfiguration.widgetMainIconSz
                        useMetrics: true

                        onLeftClicked: root.activeTab = tabEntry.index
                    }

                    Separator {
                        Layout.fillHeight: true
                        orientation: Qt.Vertical
                        thickness: CenterPieceUI.Configuration.tabSelectorWidth
                        color: Settings.colors.accentMain

                        opacity: root.activeTab === tabEntry.index ? 1 : 0
                    }
                }
            }
        }

        Separator {
            Layout.fillHeight: true
            orientation: Qt.Vertical
            color: Settings.colors.bgTint2
            opacity: Settings.colors.dimOpacity
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            sourceComponent: selectSourceComponent()
        }
    }

    Component { id: calendarPage; CenterPieceUI.CalendarPage {} }
    Component { id: weatherPage; CenterPieceUI.WeatherPage {} }

    // ────── Helper Functions ──────
    function selectSourceComponent() {
        switch (root.activeTab) {
            case root.calendarTab: return calendarPage;
            case root.weatherTab: return weatherPage;
        }
    }
}
