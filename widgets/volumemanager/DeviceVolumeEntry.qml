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

    padding: Configuration.volEntryPadding
    implicitHeight: mainContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

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
        spacing: Configuration.volEntryPadding

        GlyphButton {
            id: volEntryBtn
            enabled: root.model.canSelect
            opacity: enabled ? 1 : 0.4
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6
            Layout.rightMargin: 6

            icon: root.model.isDefault
                ? Configuration.deviceSelectedState[0]
                : Configuration.deviceSelectedState[1]
            iconSize: Configuration.mainButtonSize
            useMetrics: false
            iconColor: root.model.isDefault
                ? Settings.colors.accentMain : Settings.colors.fgMain

            onLeftClicked: {
                if (root.model.isInput)
                    Core.Audio.selectInputById(root.model.id)
                else
                    Core.Audio.selectOutputById(root.model.id)
            }
        }

        ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Configuration.volEntryPadding

                Text {
                    id: volEntryName
                    Layout.fillWidth: true

                    text: root.deviceLabel()
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.volEntryNameFontSize
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                }

                SquaredButton {
                    id: settingsBtn

                    glyph: Configuration.volEntrySettingsIcon
                    glyphSize: Configuration.secondaryButtonSize
                    color: Settings.colors.fgMain

                    onLeftClicked: {
                        VolumeActions.volumeManager()
                        root.dismissRequested()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                clip: true

                SquaredButton {
                    id: muteBtn

                    glyph: root.model.isInput
                        ? Configuration.inputMuteState[root.model.muted ? 1 : 0]
                        : Configuration.outputMuteState[root.model.muted ? 1 : 0]
                    glyphSize: Configuration.secondaryButtonSize
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Audio.setEntryMuted(
                        root.model.id, !root.model.muted)
                }

                HexagonSlider {
                    id: volumeSlider
                    Layout.fillWidth: true

                    from: 0
                    to: 100
                    value: root.model.value
                    actionable: true
                    backgroundColor: Settings.colors.bgTint2

                    onMoved: Core.Audio.setEntryVolume(root.model.id, value)
                }

                Percentage {
                    Layout.leftMargin: Configuration.volEntryRowSpacing
                    height: parent.height
                    value: String(root.model.value)

                    fontFamily: Settings.labelFontFamily
                    fontSize: Configuration.volEntryNameFontSize
                }
            }
        }
    }

    // ────── Row logic ──────
    function deviceLabel() {
        const configuredName = root.model.isInput
            ? Configuration.defaultInput : Configuration.defaultOuput

        if (root.model.nodeName === configuredName) {
            if (root.model.portName === "analog-output-speaker")
                return "Built-in Speakers"
            if (root.model.portName === "analog-input-internal-mic")
                return "Internal Microphone"
        }

        return root.model.name
    }
}
