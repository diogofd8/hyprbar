import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components
import qs.core

import "networkmanager" as NetworkUI

Pane {
    id: root

    // Raised when an action hands the user off to another window, so the host
    // popup can get out of the way instead of lingering behind it.
    signal dismissRequested()

    readonly property string panelBackgroundColor: Settings.colors.bgMain
    readonly property real targetImplicitHeight: panelContent.implicitHeight
        + root.topPadding + root.bottomPadding

    padding: WidgetConfiguration.dropDownWindowPadding
    // Entry heights already contain the transition. The shared host keeps
    // its window size fixed while its clipped panel follows this height.
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

    contentItem: ColumnLayout {
        id: panelContent

        // ────── Top Row ──────
        ColumnLayout {
            id: headerContainer
            spacing: WidgetConfiguration.mainRowPadding

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: WidgetConfiguration.mainRowPadding
                Layout.rightMargin: WidgetConfiguration.mainRowPadding
                spacing: WidgetConfiguration.mainRowHSpacing

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: WidgetConfiguration.hexSwitchSpacing

                    Glyph {
                        icon: NetworkUI.Configuration.nwWifiIcon
                        iconSize: WidgetConfiguration.widgetMainIconSz
                        iconColor: Settings.colors.fgMain
                    }

                    HexagonSwitch {
                        actionable: Network.wifiAvailable && !Network.wifiToggleBusy
                        checked: Network.wifiEnabled
                        onClicked: Network.toggleWifi()

                        backgroundColor: root.panelBackgroundColor
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                SquaredButton {
                    enabled: Network.discoveryActive && Network.wifiAvailable && Network.wifiEnabled

                    glyph: NetworkUI.Configuration.nmConnectionRefreshIcon
                    glyphSize: WidgetConfiguration.widgetMainIconSz
                    useMetrics: true
                    color: Settings.colors.fgMain

                    onLeftClicked: Network.forceWifiScan()
                    rotateOnClick: true
                }

                SquaredButton {

                    glyph: NetworkUI.Configuration.nmConnectionEditorIcon
                    glyphSize: WidgetConfiguration.widgetMainIconSz
                    useMetrics: true
                    color: Settings.colors.fgMain

                    onLeftClicked: {
                        Network.openSettings()
                        root.dismissRequested()
                    }
                }
            }

            // ────── Separator ──────
            Separator {
                Layout.fillWidth: true
                Layout.topMargin: 1
                Layout.bottomMargin: WidgetConfiguration.mainRowVMargin
                color: Settings.colors.bgTint4
            }
        }


        // ────── Connections ──────
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: NetworkUI.Configuration.contentWidth
            implicitHeight: Math.min(contents.implicitHeight, WidgetConfiguration.rowContentMaxHeight)
            contentWidth: width
            contentHeight: contents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contents
                width: scroll.width
                spacing: WidgetConfiguration.sectionVSpacing

                ColumnLayout {
                    id: activeSection

                    Layout.fillWidth: true
                    visible: Network.activeConnections.count > 0
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    Text {
                        text: "ACTIVE CONNECTIONS"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                    }

                    Repeater {
                        model: Network.activeConnections
                        delegate: NetworkUI.NetworkEntry {
                            Layout.fillWidth: true

                            onDismissRequested: root.dismissRequested()
                        }
                    }
                }

                ColumnLayout {
                    id: availableSection

                    Layout.fillWidth: true
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    Text {
                        text: "AVAILABLE CONNECTIONS"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                    }

                    Repeater {
                        model: Network.availableConnections
                        delegate: NetworkUI.NetworkEntry {
                            Layout.fillWidth: true

                            onDismissRequested: root.dismissRequested()
                        }
                    }

                    Text {
                        visible: Network.availableConnections.count === 0
                        text: Network.refreshing
                            ? "Scanning for networks…"
                            : Network.wifiAvailable && !Network.wifiEnabled
                            ? "Turn on Wi-Fi to see networks"
                            : Network.activeConnections.count > 0
                                ? "No other connections available"
                                : "No connections available"
                        color: Settings.colors.fgMain
                        opacity: Settings.colors.dimOpacity
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                    }

                    Text {
                        visible: Network.scanErrorMessage.length > 0
                        text: Network.scanErrorMessage
                        color: Settings.colors.accentError
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                    }
                }
            }
        }
    }
}
