import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components
import qs.core

import "bluetoothmanager" as BluetoothUI

Pane {
    id: root
    signal dismissRequested()

    readonly property string panelBackgroundColor: Settings.colors.bgMain
    readonly property real targetImplicitHeight: panelContent.implicitHeight + root.topPadding + root.bottomPadding

    // Overrides the remembered-device cap. The popup is rebuilt on every open, so this resets itself without any teardown.
    property bool showAllPaired: false

    readonly property bool scanSectionShown: Bluetooth.scanning || Bluetooth.scanPerformed || Bluetooth.discoveredDevices.count > 0

    padding: BluetoothUI.Configuration.widgetBoxPadding
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
            spacing: BluetoothUI.Configuration.topBarPadding

            RowLayout {
                Layout.leftMargin: BluetoothUI.Configuration.topBarPadding
                Layout.alignment: Qt.AlignVCenter
                spacing: 5

                Glyph {
                    icon: BluetoothUI.Configuration.bmBluetoothIcon
                    iconSize: BluetoothUI.Configuration.mainButtonSize
                    iconColor: Settings.colors.fgMain
                }

                HexagonSwitch {
                    actionable: Bluetooth.bluetoothAvailable && !Bluetooth.bluetoothBusy
                    checked: Bluetooth.bluetoothEnabled
                    onClicked: Bluetooth.toggleBluetooth()

                    backgroundColor: root.panelBackgroundColor
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
            }

            Glyph {
                id: isScanningBt
                Layout.rightMargin: BluetoothUI.Configuration.btScanningIconSpacing

                visible: Bluetooth.scanning

                icon: BluetoothUI.Configuration.bmIsScanningIcon
                iconSize: BluetoothUI.Configuration.secondaryButtonSize
                useMetrics: true
                iconColor: Settings.colors.accentMain

                NumberAnimation on rotation {
                    from: 360
                    to: 0
                    duration: 1500
                    loops: Animation.Infinite
                    running: isScanningBt.visible

                    onStopped: isScanningBt.rotation = 0
                }
            }

            // Takes the scanning indicator's place once the scan is over, so
            // the results can be dropped without closing the popup.
            GlyphButton {
                id: clearScannedBtn
                Layout.rightMargin: BluetoothUI.Configuration.btScanningIconSpacing

                visible: !Bluetooth.scanning && root.scanSectionShown
                enabled: visible

                icon: BluetoothUI.Configuration.bmClearScanIcon
                iconSize: BluetoothUI.Configuration.secondaryButtonSize
                iconColor: Settings.colors.accentMain
                hoverOpacity: 0
                useMetrics: true

                onLeftClicked: Bluetooth.clearScanResults()
            }

            SquaredButton {
                id: btScanBtn
                enabled: Bluetooth.bluetoothEnabled

                glyph: Bluetooth.scanning || Bluetooth.scanRequested
                    ? BluetoothUI.Configuration.bmStopScanIcon
                    : BluetoothUI.Configuration.bmInitScanIcon
                glyphSize: BluetoothUI.Configuration.mainButtonSize
                useMetrics: true
                color: btScanBtn.enabled
                    ? Settings.colors.fgMain
                    : Qt.alpha(Settings.colors.fgMain, 0.4)

                onLeftClicked: Bluetooth.toggleDiscovery()
            }

            SquaredButton {
                id: bluemanManagerBtn
                Layout.rightMargin: BluetoothUI.Configuration.topBarPadding

                glyph: BluetoothUI.Configuration.bmLauncherIcon
                glyphSize: BluetoothUI.Configuration.mainButtonSize
                useMetrics: true
                color: Settings.colors.fgMain

                onLeftClicked: {
                    Bluetooth.openSettings()
                    root.dismissRequested()
                }
            }
        }

        // ────── Separator ──────
        Separator {
            Layout.fillWidth: true
            Layout.topMargin: 1
            Layout.bottomMargin: BluetoothUI.Configuration.mainColumnGap
            color: Settings.colors.bgTint4
        }

        // ────── Devices ──────
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: BluetoothUI.Configuration.contentWidth
            implicitHeight: Math.min(contents.implicitHeight, BluetoothUI.Configuration.listMaxHeight)
            contentWidth: width
            contentHeight: contents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contents
                width: scroll.width
                spacing: BluetoothUI.Configuration.sectionSpacing

                Text {
                    Layout.fillWidth: true
                    visible: Bluetooth.statusMessage.length > 0

                    text: Bluetooth.statusMessage
                    wrapMode: Text.Wrap
                    color: Bluetooth.bluetoothAvailable && !Bluetooth.bluetoothBlocked
                        ? Settings.colors.fgMain : Settings.colors.accentAlert
                    opacity: Bluetooth.bluetoothAvailable && !Bluetooth.bluetoothBlocked ? 0.7 : 1
                    font.family: Settings.labelFontFamily
                    font.pixelSize: BluetoothUI.Configuration.subTextFontSize
                }

                Text {
                    Layout.fillWidth: true
                    visible: Bluetooth.scanErrorMessage.length > 0

                    text: Bluetooth.scanErrorMessage
                    wrapMode: Text.Wrap
                    color: Settings.colors.accentAlert
                    font.family: Settings.labelFontFamily
                    font.pixelSize: BluetoothUI.Configuration.subTextFontSize
                }

                ColumnLayout {
                    id: connectedSection

                    Layout.fillWidth: true
                    visible: Bluetooth.connectedDevices.count > 0
                    spacing: BluetoothUI.Configuration.btEntryRowSpacing

                    Text {
                        Layout.bottomMargin: 4

                        text: "CONNECTED DEVICES"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: BluetoothUI.Configuration.columnLabelFontSize
                    }

                    Repeater {
                        model: Bluetooth.connectedDevices
                        delegate: BluetoothUI.BluetoothEntry {
                            Layout.fillWidth: true

                            onDismissRequested: root.dismissRequested()
                        }
                    }
                }

                ColumnLayout {
                    id: pairedSection

                    Layout.fillWidth: true
                    visible: Bluetooth.pairedDevices.count > 0
                    spacing: BluetoothUI.Configuration.btEntryRowSpacing

                    RowLayout {
                        Layout.bottomMargin: 4

                        Text {
                            text: "PAIRED DEVICES"
                            color: Settings.colors.fgMain
                            font.family: Settings.labelFontFamily
                            font.bold: true
                            font.pixelSize: BluetoothUI.Configuration.columnLabelFontSize
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                        }

                        SquaredButton {
                            id: showAllBtn

                            visible: Bluetooth.pairedDevices.count > BluetoothUI.Configuration.pairedVisibleMax

                            rotation: root.showAllPaired ? 180 : 0
                            glyph: BluetoothUI.Configuration.btExpandIcon
                            glyphSize: BluetoothUI.Configuration.columnLabelFontSize
                            color: Settings.colors.fgMain

                            onLeftClicked: root.showAllPaired = !root.showAllPaired

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: BluetoothUI.Configuration.transitionMs
                                    easing.type: Easing.InOutCubic
                                }
                            }
                        }
                    }

                    Repeater {
                        model: Bluetooth.pairedDevices
                        delegate: BluetoothUI.BluetoothEntry {
                            required property int index

                            Layout.fillWidth: true
                            visible: root.showAllPaired || index < BluetoothUI.Configuration.pairedVisibleMax

                            onDismissRequested: root.dismissRequested()
                        }
                    }
                }

                ColumnLayout {
                    id: scanningSection

                    Layout.fillWidth: true
                    visible: root.scanSectionShown
                    spacing: BluetoothUI.Configuration.btEntryRowSpacing

                    Text {
                        Layout.bottomMargin: 4

                        text: "SCANNED DEVICES"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: BluetoothUI.Configuration.columnLabelFontSize
                    }

                    Repeater {
                        model: Bluetooth.discoveredDevices
                        delegate: BluetoothUI.BluetoothEntry {
                            Layout.fillWidth: true
                            onDismissRequested: root.dismissRequested()
                        }
                    }

                    Text {
                        visible: Bluetooth.discoveredDevices.count === 0

                        text: Bluetooth.scanning ? "Scanning for devices…" : "No Bluetooth devices found."
                        color: Settings.colors.fgMain
                        opacity: 0.7
                        font.family: Settings.labelFontFamily
                        font.pixelSize: BluetoothUI.Configuration.subTextFontSize
                    }
                }
            }
        }
    }
}
