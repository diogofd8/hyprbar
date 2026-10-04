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

    padding: WidgetConfiguration.dropDownWindowPadding
    implicitHeight: root.targetImplicitHeight
    clip: true

    // PopoutHost draws the panel background shared by every widget. Null, not
    // omitted, so the Controls style doesn't add a default one.
    background: null

    contentItem: ColumnLayout {
        id: panelContent

        // ────── Top Row ──────
        ColumnLayout {
            id: headerContainer
            spacing: WidgetConfiguration.mainRowPadding

            RowLayout{
                Layout.fillWidth: true
                Layout.leftMargin: WidgetConfiguration.mainRowPadding
                Layout.rightMargin: WidgetConfiguration.mainRowPadding
                spacing: WidgetConfiguration.mainRowHSpacing

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: WidgetConfiguration.hexSwitchSpacing

                    Glyph {
                        icon: BluetoothUI.Configuration.bmBluetoothIcon
                        iconSize: WidgetConfiguration.widgetMainIconSz
                        iconColor: Settings.colors.fgMain
                    }

                    HexagonSwitch {
                        actionable: Bluetooth.bluetoothAvailable && !Bluetooth.bluetoothBusy
                        checked: Bluetooth.bluetoothEnabled
                        onClicked: Bluetooth.toggleBluetooth()

                        backgroundColor: root.panelBackgroundColor
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Glyph {
                    id: isScanningBt
                    Layout.rightMargin: WidgetConfiguration.statusIconExtraSpacing

                    visible: Bluetooth.scanning

                    icon: BluetoothUI.Configuration.bmIsScanningIcon
                    iconSize: WidgetConfiguration.widgetSecondaryIconSz
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
                    Layout.rightMargin: WidgetConfiguration.statusIconExtraSpacing

                    visible: !Bluetooth.scanning && root.scanSectionShown
                    enabled: visible

                    icon: BluetoothUI.Configuration.bmClearScanIcon
                    iconSize: WidgetConfiguration.widgetSecondaryIconSz
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
                    glyphSize: WidgetConfiguration.widgetMainIconSz
                    useMetrics: true
                    color: btScanBtn.enabled
                        ? Settings.colors.fgMain
                        : Qt.alpha(Settings.colors.fgMain, Settings.colors.disabledOpacity)

                    onLeftClicked: Bluetooth.toggleDiscovery()
                }

                SquaredButton {
                    id: bluemanManagerBtn

                    glyph: BluetoothUI.Configuration.bmLauncherIcon
                    glyphSize: WidgetConfiguration.widgetMainIconSz
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
                Layout.bottomMargin: WidgetConfiguration.mainRowVMargin
                color: Settings.colors.bgTint4
            }
        }

        // ────── Devices ──────
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: BluetoothUI.Configuration.contentWidth
            implicitHeight: Math.min(contents.implicitHeight, WidgetConfiguration.rowContentMaxHeight)
            contentWidth: width
            contentHeight: contents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contents
                width: scroll.width
                spacing: WidgetConfiguration.sectionVSpacing

                Text {
                    Layout.fillWidth: true
                    visible: Bluetooth.statusMessage.length > 0

                    text: Bluetooth.statusMessage
                    wrapMode: Text.Wrap
                    color: Bluetooth.bluetoothAvailable && !Bluetooth.bluetoothBlocked
                        ? Settings.colors.fgMain : Settings.colors.accentAlert
                    opacity: Bluetooth.bluetoothAvailable && !Bluetooth.bluetoothBlocked ? 0.7 : 1
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                }

                Text {
                    Layout.fillWidth: true
                    visible: Bluetooth.scanErrorMessage.length > 0

                    text: Bluetooth.scanErrorMessage
                    wrapMode: Text.Wrap
                    color: Settings.colors.accentAlert
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                }

                ColumnLayout {
                    id: connectedSection

                    Layout.fillWidth: true
                    visible: Bluetooth.connectedDevices.count > 0
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    Text {
                        text: "CONNECTED DEVICES"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
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
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    RowLayout {
                        Text {
                            text: "PAIRED DEVICES"
                            color: Settings.colors.fgMain
                            font.family: Settings.labelFontFamily
                            font.bold: true
                            font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        SquaredButton {
                            id: showAllBtn

                            visible: Bluetooth.pairedDevices.count > BluetoothUI.Configuration.pairedVisibleMax

                            rotation: root.showAllPaired ? 180 : 0
                            glyph: BluetoothUI.Configuration.btExpandIcon
                            glyphSize: WidgetConfiguration.sectionRowLabelFontSz
                            color: Settings.colors.fgMain

                            onLeftClicked: root.showAllPaired = !root.showAllPaired

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: WidgetConfiguration.transitionMs
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
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    Text {
                        text: "SCANNED DEVICES"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
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
                        opacity: Settings.colors.dimOpacity
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                    }
                }
            }
        }
    }
}
