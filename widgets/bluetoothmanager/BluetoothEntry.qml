import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import qs
import qs.components
import qs.widgets
import qs.core as Core

Controls.Pane {
    id: root
    required property var model

    property bool expanded: false
    readonly property bool hasError: root.model.errorMessage.length > 0

    readonly property bool canExpand: BluetoothActions.canExpand(root.model)
    readonly property bool bottomShown: (root.expanded && root.canExpand) || root.hasError

    readonly property string entryIcon: BluetoothActions.entryIcon(root.model)
    readonly property string statusText: BluetoothActions.statusText(root.model)

    // ────── Dimensioning ──────
    leftPadding: WidgetConfiguration.entryHPadding
    rightPadding: WidgetConfiguration.entryHPadding
    topPadding: WidgetConfiguration.entryVPadding
    bottomPadding: WidgetConfiguration.entryVPadding
    implicitHeight: mainContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    background: Rectangle {
        color: Settings.colors.bgTint2
    }

    contentItem: RowLayout {
        id: mainContent
        spacing: WidgetConfiguration.entryHPadding

        Glyph {
            id: entryGlyph
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: WidgetConfiguration.entryIconHPadding
            Layout.rightMargin: WidgetConfiguration.entryIconHPadding

            icon: root.entryIcon
            iconSize: WidgetConfiguration.entryRowMainIconSz
            useMetrics: false
        }

        ColumnLayout {
            spacing: WidgetConfiguration.entryRowVSpacing

            // ────── Main Row ──────
            RowLayout {
                id: mainRow

                Layout.fillWidth: true
                Layout.preferredHeight: WidgetConfiguration.entryRowMainIconSz
                spacing: WidgetConfiguration.entryTitleRowHSpacing

                Behavior on Layout.topMargin { Anim {} }

                Text {
                    id: deviceName
                    Layout.fillWidth: true

                    text: root.model.name
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
                }

                SquaredButton {
                    id: pairBtn

                    visible: root.model.canPair

                    glyph: Configuration.btPairIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Bluetooth.pair(root.model.address)
                }

                SquaredButton {
                    id: cancelBtn

                    visible: root.model.canCancel

                    glyph: Configuration.btCancelIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.accentAlert

                    onLeftClicked: Core.Bluetooth.cancelOperation(root.model.address)
                }

                SquaredButton {
                    id: connectionBtn

                    visible: root.model.canConnect || root.model.canDisconnect

                    glyph: root.model.canDisconnect
                        ? Configuration.btDisconnectIcon
                        : Configuration.btConnectIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.fgMain

                    onLeftClicked: root.runConnectionAction()
                }

                SquaredButton {
                    id: forgetBtn

                    visible: root.model.canForget

                    glyph: Configuration.btForgetIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Bluetooth.forget(root.model.address)
                }

                SquaredButton {
                    id: expandBtn

                    visible: root.canExpand
                    rotation: root.bottomShown ? 180 : 0
                    glyph: Configuration.btExpandIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.fgMain

                    onLeftClicked: {
                        const wasOpen = root.bottomShown
                        root.dismissRow()
                        root.expanded = !wasOpen
                    }

                    Behavior on rotation { Anim {} }
                }
            }

            // ────── Extended Row ──────
            CollapsibleRow {
                id: bottom
                shown: root.bottomShown
                Layout.fillWidth: true
                spacing: WidgetConfiguration.entryExtendedRowHSpacing

                // ────── Device Details ──────
                // Future: For now similar to NetworkManager's details but perhaps this should be different
                // Including trusted status, perhaps more bluetooth detailed information, in more than 1 line
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.canExpand
                    opacity: Settings.colors.dimOpacity
                    spacing: WidgetConfiguration.entryExtendedRowHSpacing

                    Text {
                        text: root.model.address

                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                    }

                    Circle {
                        Layout.alignment: Qt.AlignCenter

                        visible: model.batteryAvailable
                        diameter: Settings.separatorDotSize
                        color: Settings.colors.fgMain
                    }

                    Text {
                        visible: model.batteryAvailable
                        text: BluetoothActions.batteryText(root.model)

                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                    }
                }

                Item {
                    Layout.fillWidth: true
                    visible: !root.canExpand
                }

                SquaredButton {
                    id: dismissBtn
                    Layout.fillHeight: true
                    Layout.preferredWidth: expandBtn.implicitWidth

                    // dismissBtn doubles as empty padding aligned with expandBtn
                    enabled: root.hasError
                    opacity: root.hasError ? 1 : 0

                    glyph: Configuration.btDismissIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Bluetooth.clearEntryError(root.model.address)

                    Behavior on opacity { Anim {} }
                }
            }

            // ────── Status Row ──────
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                visible: root.statusText.length > 0

                text: root.statusText
                wrapMode: Text.Wrap
                color: root.hasError ? Settings.colors.accentError : Settings.colors.fgMain
                opacity: root.hasError ? 1 : 0.7
                font.family: Settings.labelFontFamily
                font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
            }
        }
    }

    // ────── Row logic ──────
    function dismissRow() {
        Core.Bluetooth.clearEntryError(root.model.address)
    }

    function runConnectionAction() {
        if (root.model.canDisconnect)
            Core.Bluetooth.disconnect(root.model.address)
        else if (root.model.canConnect)
            Core.Bluetooth.connect(root.model.address)
    }
}
