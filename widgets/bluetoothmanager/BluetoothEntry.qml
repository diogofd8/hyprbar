import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import qs
import qs.components
import qs.core as Core

Controls.Pane {
    id: root
    required property var model
    signal dismissRequested()

    property bool expanded: false
    readonly property bool hasError: root.model.errorMessage.length > 0

    readonly property bool canExpand: BluetoothActions.canExpand(root.model)
    readonly property bool bottomShown: (root.expanded && root.canExpand) || root.hasError

    readonly property string entryIcon: BluetoothActions.entryIcon(root.model)
    readonly property string statusText: BluetoothActions.statusText(root.model)

    // ────── Dimensioning ──────
    padding: Configuration.btEntryPadding
    implicitHeight: mainContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    // ────── Animations ──────
    Behavior on implicitHeight {
        SmoothedAnimation {
            duration: Configuration.transitionMs
            velocity: -1
            reversingMode: SmoothedAnimation.Eased
        }
    }

    background: Rectangle {
        color: Settings.colors.bgTint2
    }

    contentItem: RowLayout {
        id: mainContent
        spacing: Configuration.btEntryPadding

        Glyph {
            id: entryGlyph
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6
            Layout.rightMargin: 6

            icon: root.entryIcon
            iconSize: Configuration.mainButtonSize
            useMetrics: false
        }

        ColumnLayout {
            spacing: Configuration.btEntryExpandedRowSpacing

            // ────── Main Row ──────
            RowLayout {
                id: mainRow
                Layout.fillWidth: true
                spacing: Configuration.btEntryPadding

                Text {
                    id: deviceName
                    Layout.fillWidth: true

                    text: root.model.name
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.btNameFontSize
                }

                SquaredButton {
                    id: pairBtn

                    visible: root.model.canPair
                    enabled: root.model.canPair

                    glyph: Configuration.btPairIcon
                    glyphSize: Configuration.secondaryButtonSize
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Bluetooth.pair(root.model.address)
                }

                SquaredButton {
                    id: cancelBtn

                    visible: root.model.canCancel
                    enabled: root.model.canCancel

                    glyph: Configuration.btCancelIcon
                    glyphSize: Configuration.secondaryButtonSize
                    color: Settings.colors.accentAlert

                    onLeftClicked: Core.Bluetooth.cancelOperation(root.model.address)
                }

                SquaredButton {
                    id: connectionBtn

                    visible: root.model.canConnect || root.model.canDisconnect
                    enabled: root.model.canConnect || root.model.canDisconnect

                    glyph: root.model.canDisconnect
                        ? Configuration.btDisconnectIcon
                        : Configuration.btConnectIcon
                    glyphSize: Configuration.secondaryButtonSize
                    color: Settings.colors.fgMain

                    onLeftClicked: root.runConnectionAction()
                }

                SquaredButton {
                    id: forgetBtn

                    visible: root.model.canForget
                    enabled: root.model.canForget

                    glyph: Configuration.btForgetIcon
                    glyphSize: Configuration.secondaryButtonSize
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Bluetooth.forget(root.model.address)
                }

                SquaredButton {
                    id: expandBtn

                    visible: root.canExpand
                    rotation: root.bottomShown ? 180 : 0
                    glyph: Configuration.btExpandIcon
                    glyphSize: Configuration.secondaryButtonSize
                    color: Settings.colors.fgMain

                    onLeftClicked: {
                        const wasOpen = root.bottomShown
                        root.dismissRow()
                        root.expanded = !wasOpen
                    }

                    Behavior on rotation {
                        NumberAnimation {
                            duration: Configuration.transitionMs
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }

            // ────── Extended Row ──────
            RowLayout {
                id: bottom
                visible: root.bottomShown
                clip: true

                Layout.fillWidth: true
                Layout.topMargin: visible ? Configuration.btEntryExpandedRowSpacing : 0
                Layout.bottomMargin: visible ? Configuration.btEntryExpandedRowSpacing : 0

                spacing: Configuration.btEntryPadding

                // ────── Device Details ──────
                // Future: For now similar to NetworkManager's details but perhaps this should be different
                // Including trusted status, perhaps more bluetooth detailed information, in more than 1 line
                Row {
                    Layout.fillWidth: true
                    visible: root.canExpand
                    opacity: 0.7
                    spacing: 4

                    Text {
                        text: root.model.address

                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: Settings.smallCapsFontSize
                    }

                    Circle {
                        visible: model.batteryAvailable
                        diameter: 2
                        color: Settings.colors.fgMain
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: model.batteryAvailable
                        text: BluetoothActions.batteryText(root.model)

                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: Settings.smallCapsFontSize
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: !root.canExpand
                    color: "transparent"
                }

                // dismissBtn doubles as empty padding aligned with expandBtn
                SquaredButton {
                    id: dismissBtn
                    Layout.fillHeight: true
                    Layout.preferredWidth: expandBtn.implicitWidth

                    enabled: root.hasError
                    opacity: root.hasError ? 1 : 0

                    glyph: Configuration.btDismissIcon
                    glyphSize: Configuration.secondaryButtonSize
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Bluetooth.clearEntryError(root.model.address)

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Configuration.transitionMs
                            easing.type: Easing.InOutCubic
                        }
                    }
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
                font.pixelSize: Settings.smallCapsFontSize
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
