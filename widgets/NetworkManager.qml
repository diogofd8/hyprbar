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

    padding: NetworkUI.Configuration.widgetBoxPadding
    // Entry heights already contain the transition. Propagate that same
    // intermediate value to PopupWindow instead of easing it a second time.
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
        RowLayout {
            Layout.fillWidth: true
            spacing: NetworkUI.Configuration.topBarPadding

            RowLayout {
                Layout.leftMargin: NetworkUI.Configuration.topBarPadding
                Layout.alignment: Qt.AlignVCenter
                spacing: 5

                Glyph {
                    icon: NetworkUI.Configuration.nwWifiIcon
                    iconSize: NetworkUI.Configuration.mainButtonSize
                    iconColor: Settings.colors.fgMain
                }

                NetworkUI.WifiSwitch {
                    backgroundColor: root.panelBackgroundColor
                }
            }

            // Text {
            //     Layout.fillWidth: true
            //     visible: !Network.wifiAvailable || Network.wifiErrorMessage.length > 0
            //     text: Network.wifiErrorMessage.length > 0
            //         ? Network.wifiErrorMessage
            //         : Network.wifiPresent
            //             ? "Wi-Fi hardware locked" : "Wi-Fi adapter unavailable"
            //     wrapMode: Text.Wrap
            //     color: Settings.colors.accentAlert
            //     font.family: Settings.labelFontFamily
            //     font.pixelSize: NetworkUI.Configuration.subTextFontSize
            // }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
            }

            NetworkUI.SquaredButton {
                enabled: Network.discoveryActive && Network.wifiAvailable && Network.wifiEnabled

                glyph: NetworkUI.Configuration.nmConnectionRefreshIcon
                glyphSize: NetworkUI.Configuration.mainButtonSize
                useMetrics: true
                color: Settings.colors.fgMain

                onLeftClicked: Network.forceWifiScan()
                rotateOnClick: true
            }

            NetworkUI.SquaredButton {
                Layout.rightMargin: NetworkUI.Configuration.topBarPadding

                glyph: NetworkUI.Configuration.nmConnectionEditorIcon
                glyphSize: NetworkUI.Configuration.mainButtonSize
                useMetrics: true
                color: Settings.colors.fgMain

                onLeftClicked: {
                    Network.openSettings()
                    root.dismissRequested()
                }
            }
        }

        // ────── Separator ──────
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 1
            Layout.bottomMargin: NetworkUI.Configuration.mainColumnGap
            implicitHeight: 1
            color: Settings.colors.bgTint4
        }

        // ────── Connections ──────
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: NetworkUI.Configuration.contentWidth
            implicitHeight: Math.min(contents.implicitHeight, NetworkUI.Configuration.listMaxHeight)
            contentWidth: width
            contentHeight: contents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contents
                width: scroll.width
                spacing: NetworkUI.Configuration.sectionSpacing

                ColumnLayout {
                    id: activeSection

                    Layout.fillWidth: true
                    visible: Network.activeConnections.count > 0
                    spacing: NetworkUI.Configuration.nwEntryRowSpacing

                    Text {
                        Layout.bottomMargin: 4

                        text: "ACTIVE CONNECTIONS"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: NetworkUI.Configuration.columnLabelFontSize
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
                    spacing: NetworkUI.Configuration.nwEntryRowSpacing

                    Text {
                        Layout.bottomMargin: 4

                        text: "AVAILABLE CONNECTIONS"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: NetworkUI.Configuration.columnLabelFontSize
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
                        opacity: 0.7
                        font.family: Settings.labelFontFamily
                        font.pixelSize: NetworkUI.Configuration.subTextFontSize
                    }

                    Text {
                        visible: Network.scanErrorMessage.length > 0
                        text: Network.scanErrorMessage
                        color: Settings.colors.accentError
                        font.family: Settings.labelFontFamily
                        font.pixelSize: NetworkUI.Configuration.subTextFontSize
                    }
                }
            }
        }
    }
}
