import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import qs
import qs.components
import qs.core as Core

Controls.Pane {
    id: root
    required property var model
    // Raised when an action hands the user off to another window, so the host
    // popup can get out of the way instead of lingering behind it.
    signal dismissRequested()

    property bool expanded: false
    readonly property bool hasError: root.model.errorMessage.length > 0
    readonly property bool askingPassword: root.model.status === "PasswordRequired"
    readonly property bool forcedOpen: root.hasTransientStatus || root.hasError || root.askingPassword
    readonly property bool isActionable: root.model.canConnect || root.model.canDisconnect
    readonly property bool hasTransientStatus: root.model.state === "Connecting" || root.model.state === "Disconnecting"
    readonly property bool bottomShown: root.expanded || root.forcedOpen

    readonly property string entryIcon: NetworkActions.entryIcon(root.model)
    readonly property bool needsExternalSetup:
        NetworkActions.needsExternalSetup(root.model)
    readonly property string statusText: makeStatusText()

    // ────── Dimensioning ──────
    padding: Configuration.nwEntryPadding
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

    contentItem: ColumnLayout {
        id: mainContent

        spacing: 0

        // ────── Main Row ──────
        RowLayout {
            id: mainRow
            Layout.fillWidth: true
            spacing: Configuration.nwEntryPadding

            Glyph {
                id: entryGlyph
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 6
                Layout.rightMargin: 6

                icon: root.entryIcon
                iconSize: Configuration.mainButtonSize
                useMetrics: false
            }

            Text {
                id: networkName
                Layout.fillWidth: true

                text: root.model.name
                elide: Text.ElideRight
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: Configuration.nwNameFontSize
            }

            SquaredButton {
                id: compactConnectionBtn

                visible: root.isActionable
                enabled: root.isActionable

                glyph: root.model.state === "Connected"
                    ? Configuration.nwDisconnectIcon
                    : Configuration.nwConnectIcon
                glyphSize: Configuration.secondaryButtonSize
                color: Settings.colors.fgMain

                onLeftClicked: root.runConnectionAction()
            }

            SquaredButton {
                id: settingsBtn

                visible: root.model.canEdit
                enabled: root.model.canEdit
                glyph: Configuration.nwEditConnectionIcon
                glyphSize: Configuration.secondaryButtonSize
                color: Settings.colors.fgMain

                onLeftClicked: {
                    Core.Network.editConnection(root.model.entryId)
                    root.dismissRequested()
                }
            }

            SquaredButton {
                id: expandBtn

                rotation: root.bottomShown ? 180 : 0
                glyph: Configuration.nwExpandIcon
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
            Layout.topMargin: visible ? Configuration.nwEntryExpandedRowSpacing : 0
            Layout.bottomMargin: visible ? Configuration.nwEntryExpandedRowSpacing : 0

            spacing: Configuration.nwEntryPadding

            // Fake padding the size of entryGlyph (copied its margins too)
            Rectangle {
                Layout.fillHeight: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                implicitWidth: entryGlyph.implicitWidth
                color: "transparent"
            }

            // ────── Network Details ──────
            Row {
                Layout.fillWidth: true
                opacity: 0.7
                spacing: 4
                visible: !root.askingPassword

                Text {
                    text: NetworkActions.connectionTypeText(root.model)

                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Settings.smallCapsFontSize
                }

                Circle {
                    diameter: 2
                    color: Settings.colors.fgMain
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.model.signalStrength + "%"

                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Settings.smallCapsFontSize
                }
            }

            Controls.TextField {
                id: passwordField
                Layout.fillWidth: true

                visible: root.askingPassword

                placeholderText: "password"
                echoMode: TextInput.Password
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize

                background: Rectangle {
                    color: Settings.colors.bgTint1
                    border.color: Settings.colors.bgTint4
                    border.width: 1
                }

                onAccepted: root.joinNetwork()
                onVisibleChanged: if (visible) forceActiveFocus()
            }

            SquaredButton {
                id: connectBtn
                Layout.fillHeight: true
                borderWidth: 1
                borderColor: Settings.colors.bgTint4

                visible: root.askingPassword
                enabled: root.model.canSubmitPassword && passwordField.text.length > 0

                glyph: Configuration.nwSendIcon
                glyphSize: Configuration.secondaryButtonSize
                color: Settings.colors.fgMain
                opacity: connectBtn.enabled ? 1 : 0.7

                onLeftClicked: root.joinNetwork()
            }

            // dismissBtn doubles as empty padding aligned with expandBtn
            SquaredButton {
                id: dismissBtn
                Layout.fillHeight: true
                Layout.preferredWidth: expandBtn.implicitWidth

                enabled: root.hasError
                opacity: root.hasError ? 1 : 0

                glyph: Configuration.nwDismissIcon
                glyphSize: Configuration.secondaryButtonSize
                color: Settings.colors.fgMain

                onLeftClicked: Core.Network.clearEntryError(root.model.entryId)

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
            color: root.hasError
                ? Settings.colors.accentError : Settings.colors.fgMain
            opacity: root.hasError ? 1 : 0.7
            font.family: Settings.labelFontFamily
            font.pixelSize: Settings.smallCapsFontSize
        }
    }

    // ────── Row logic ──────
    function dismissRow() {
        if (root.model.canCancel) {
            Core.Network.cancelConnection(root.model.entryId)
            passwordField.clear()
        }
        Core.Network.clearEntryError(root.model.entryId)
    }

    function runConnectionAction() {
        if (root.model.canDisconnect)
            Core.Network.disconnectEntry(root.model.entryId)
        else if (root.model.canConnect)
            Core.Network.connectEntry(root.model.entryId)
    }

    function joinNetwork() {
        if (root.model.canSubmitPassword && passwordField.text.length > 0) {
            Core.Network.submitPassword(root.model.entryId, passwordField.text)
            passwordField.clear()
        }
    }

    // The single line under the row. First matching case wins.
    function makeStatusText() {
        if (root.hasError) return root.model.errorMessage
        if (root.askingPassword) return ""            // the field says it all
        if (root.model.state === "Connecting") return "Connecting…"
        if (root.model.state === "Disconnecting") return "Disconnecting…"
        if (root.expanded && root.needsExternalSetup)
            return "Configure this network in NetworkManager to connect."
        return ""
    }
}
