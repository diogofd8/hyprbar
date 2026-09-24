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

    readonly property bool isActionable: root.model.canConnect || root.model.canDisconnect
    readonly property bool hasTransientStatus:
        root.model.state === "Connecting"
        || root.model.state === "Disconnecting"
    readonly property bool bottomShown: root.expanded
        || root.hasTransientStatus
        || root.model.errorMessage.length > 0
    readonly property var wifiIcons: root.model.security === "open"
        ? Configuration.nwWifiOpenIcon
        : Configuration.nwWifiProtectedIcon
    readonly property int signalLevel: root.model.kind === "wifi"
        ? Math.min(Core.Network.wifiSignalLevel(root.model.signalStrength),
            root.wifiIcons.length - 1)
        : 0
    readonly property string entryIcon: root.model.kind === "ethernet"
        ? Configuration.nwEthernetIcon
        : root.wifiIcons[root.signalLevel]
    readonly property real targetImplicitHeight: mainContent.implicitHeight
        + root.topPadding + root.bottomPadding
    property real animatedHeight: root.targetImplicitHeight

    padding: Configuration.nwEntryPadding
    implicitHeight: root.animatedHeight
    Layout.preferredHeight: root.animatedHeight
    clip: true

    // Publish one animated size to every parent layout. SmoothedAnimation
    // preserves velocity if the layout target changes or the user reverses the
    // transition before it has finished.
    Behavior on animatedHeight {
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
            Layout.leftMargin: 4
            Layout.rightMargin: Layout.leftMargin
            spacing: Configuration.nwEntryPadding

            Glyph {
                id: entryGlyph

                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: Configuration.nwEntryPadding

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

            // Compact action: preserve the contracted view exactly as an
            // icon button.
            SquaredButton {
                id: compactConnectionBtn

                visible: !root.expanded && root.isActionable
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

                rotation: root.expanded ? 180 : 0
                glyph: Configuration.nwExpandIcon
                glyphSize: Configuration.secondaryButtonSize
                color: Settings.colors.fgMain

                onLeftClicked: root.expanded = !root.expanded

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
            Layout.leftMargin: 4
            Layout.rightMargin: Layout.leftMargin
            Layout.topMargin: visible ? Configuration.nwEntryExpandedRowSpacing : 0
            Layout.bottomMargin: visible ? Configuration.nwEntryExpandedRowSpacing : 0

            spacing: Configuration.nwEntryPadding

            // Reserved spacing below entryGlyph
            Rectangle {
                Layout.fillHeight: true
                Layout.rightMargin: Configuration.nwEntryPadding
                implicitWidth: entryGlyph.implicitWidth
                color: "transparent"
            }

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                text: root.detailText()
                elide: Text.ElideRight
                color: Settings.colors.fgMain
                opacity: 0.7
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize
            }

            Controls.TextField {
                id: passwordField

                Layout.preferredWidth: 140
                visible: root.model.status === "PasswordRequired"
                placeholderText: "Wi-Fi password"
                echoMode: TextInput.Password
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize

                background: Rectangle {
                    color: Settings.colors.bgMain
                    border.color: Settings.colors.bgTint4
                    border.width: 1
                }

                onAccepted: if (joinBtn.enabled) joinBtn.leftClicked()
                onVisibleChanged: if (visible) forceActiveFocus()
            }

            TextButton {
                id: joinBtn
                paddingX: 12
                paddingY: 8

                visible: root.model.status === "PasswordRequired"
                enabled: root.model.canSubmitPassword && passwordField.text.length > 0

                text: "Join"

                onLeftClicked: {
                    Core.Network.submitPassword(root.model.entryId, passwordField.text)
                    passwordField.clear()
                }
            }

            TextButton {
                id: cancelBtn
                paddingX: 12
                paddingY: 8

                visible: root.model.status === "PasswordRequired"
                enabled: root.model.canCancel

                text: "Cancel"

                onLeftClicked: {
                    Core.Network.cancelConnection(root.model.entryId)
                    passwordField.clear()
                }
            }

            TextButton {
                id: connectionBtn
                paddingX: 12
                paddingY: 8

                visible: root.expanded && root.isActionable
                enabled: root.isActionable

                text: root.model.state === "Connected" ? "Disconnect" : "Connect"

                onLeftClicked: root.runConnectionAction()
            }
        }

        // ────── Connection Diagnosis Row ──────
        RowLayout {
            Layout.fillWidth: true
            visible: root.model.errorMessage.length > 0
            spacing: Configuration.nwEntryExpandedRowSpacing

            Text {
                Layout.fillWidth: true
                text: root.model.errorMessage
                color: Settings.colors.accentError
                wrapMode: Text.Wrap
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize
            }

            TextButton {
                paddingX: 12
                paddingY: 8
                text: "Retry"
                visible: root.model.canConnect
                enabled: root.model.canConnect
                onLeftClicked: Core.Network.connectEntry(root.model.entryId)
            }

            TextButton {
                paddingX: 12
                paddingY: 8
                text: "Dismiss"
                visible: root.model.canConnect
                enabled: root.model.canConnect
                onLeftClicked: Core.Network.clearEntryError(root.model.entryId)
            }

            Text {
                Layout.fillWidth: true
                visible: root.expanded
                    && root.model.kind === "wifi"
                    && (root.model.security === "enterprise"
                        || root.model.security === "unsupported")
                    && !root.model.canConnect && !root.model.canEdit
                text: "Configure this network in NetworkManager to connect."
                color: Settings.colors.fgMain
                opacity: 0.7
                wrapMode: Text.Wrap
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize
            }
        }
    }

    function runConnectionAction() {
        if (root.model.canDisconnect)
            Core.Network.disconnectEntry(root.model.entryId)
        else if (root.model.canConnect)
            Core.Network.connectEntry(root.model.entryId)
    }

    function detailText() {
        if (root.model.state === "Connecting")
            return root.model.status === "PasswordRequired"
                ? "Password" : "Connecting…"
        if (root.model.state === "Disconnecting")
            return "Disconnecting…"
        if (root.model.kind === "ethernet")
            return root.model.interfaceName
        if (root.model.security === "open")
            return "Open · " + root.model.signalStrength + "%"
        if (root.model.security === "enterprise")
            return "Enterprise · " + root.model.signalStrength + "%"
        if (root.model.security === "unsupported")
            return "Other · " + root.model.signalStrength + "%"
        return "Secured · " + root.model.signalStrength + "%"
    }
}
