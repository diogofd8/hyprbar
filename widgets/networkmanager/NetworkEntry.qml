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
                    id: networkName
                    Layout.fillWidth: true

                    text: root.model.name
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
                }

                SquaredButton {
                    id: compactConnectionBtn

                    visible: root.isActionable

                    glyph: root.model.state === "Connected"
                        ? Configuration.nwDisconnectIcon
                        : Configuration.nwConnectIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.fgMain

                    onLeftClicked: root.runConnectionAction()
                }

                SquaredButton {
                    id: settingsBtn

                    visible: root.model.canEdit
                    glyph: Configuration.nwEditConnectionIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
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

                // ────── Network Details ──────
                RowLayout {
                    Layout.fillWidth: true
                    visible: !root.askingPassword
                    opacity: Settings.colors.dimOpacity
                    spacing: WidgetConfiguration.entryExtendedRowHSpacing

                    Text {
                        text: NetworkActions.connectionTypeText(root.model)

                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                    }

                    Circle {
                        Layout.alignment: Qt.AlignCenter
                        diameter: Settings.separatorDotSize
                        color: Settings.colors.fgMain
                    }

                    Text {
                        text: root.model.signalStrength + "%"

                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
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
                    font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz

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
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.fgMain
                    opacity: connectBtn.enabled ? 1 : 0.7

                    onLeftClicked: root.joinNetwork()
                }

                SquaredButton {
                    id: dismissBtn
                    Layout.fillHeight: true
                    Layout.preferredWidth: expandBtn.implicitWidth

                    // dismissBtn doubles as empty padding aligned with expandBtn
                    enabled: root.hasError
                    opacity: root.hasError ? 1 : 0

                    glyph: Configuration.nwDismissIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Network.clearEntryError(root.model.entryId)

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
                color: root.hasError
                    ? Settings.colors.accentError : Settings.colors.fgMain
                opacity: root.hasError ? 1 : 0.7
                font.family: Settings.labelFontFamily
                font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
            }
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
