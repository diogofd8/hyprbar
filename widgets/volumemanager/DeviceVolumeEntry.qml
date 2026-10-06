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
    signal dismissRequested()

    // ────── Dimensioning ──────
    leftPadding: WidgetConfiguration.entryHPadding
    rightPadding: WidgetConfiguration.entryHPadding
    topPadding: WidgetConfiguration.entryVPadding
    bottomPadding: WidgetConfiguration.entryVPadding
    implicitHeight: mainContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    Behavior on implicitHeight { Anim {} }

    background: Rectangle {
        color: Settings.colors.bgTint2
    }

    contentItem: RowLayout {
        id: mainContent
        spacing: WidgetConfiguration.entryHPadding

        GlyphButton {
            id: volEntryBtn
            enabled: root.model.canSelect
            opacity: enabled ? 1 : Settings.colors.disabledOpacity
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: WidgetConfiguration.entryIconHPadding
            Layout.rightMargin: WidgetConfiguration.entryIconHPadding

            icon: root.model.isDefault
                ? Configuration.deviceSelectedState[0]
                : Configuration.deviceSelectedState[1]
            iconSize: WidgetConfiguration.entryRowMainIconSz
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
            spacing: WidgetConfiguration.entryRowVSpacing

            RowLayout {
                id: mainRow
                Layout.fillWidth: true
                Layout.preferredHeight: WidgetConfiguration.entryRowMainIconSz
                spacing: WidgetConfiguration.entryTitleRowHSpacing

                Text {
                    id: volEntryName
                    Layout.fillWidth: true

                    text: root.deviceLabel()
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
                }

                Item {
                    Layout.fillWidth: true
                }

                SquaredButton {
                    id: settingsBtn

                    glyph: Configuration.volEntrySettingsIcon
                    glyphSize: WidgetConfiguration.widgetSecondaryIconSz
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

                SquaredButton {
                    id: muteBtn

                    glyph: root.model.isInput
                        ? Configuration.inputMuteState[root.model.muted ? 1 : 0]
                        : Configuration.outputMuteState[root.model.muted ? 1 : 0]
                    glyphSize: WidgetConfiguration.widgetSecondaryIconSz
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Audio.setEntryMuted(
                        root.model.id, !root.model.muted)
                }

                RowLayout {
                    id: volumeSliderContainer
                    spacing: WidgetConfiguration.entryExtendedRowHSpacing
                    Layout.topMargin: WidgetConfiguration.sliderExtraSpacing
                    Layout.bottomMargin: WidgetConfiguration.sliderExtraSpacing

                    clip: true

                    HexagonSlider {
                        id: volumeSlider
                        Layout.fillWidth: true

                        from: 0
                        to: 100
                        value: root.model.value
                        actionable: true
                        bgFill: Settings.colors.bgTint2

                        onMoved: Core.Audio.setEntryVolume(root.model.id, value)
                    }

                    Percentage {
                        height: parent.height
                        value: String(root.model.value)

                        fontFamily: Settings.labelFontFamily
                        fontSize: WidgetConfiguration.entryRowDefaultFontSz
                    }
                }
            }
        }
    }

    // ────── Row logic ──────
    function deviceLabel() {
        const configuredName = root.model.isInput
            ? Settings.volumeBuiltInInputNodeName : Settings.volumeBuiltInOutputNodeName

        if (root.model.nodeName === configuredName) {
            if (root.model.portName === Settings.volumeBuiltInSpeakerPortName)
                return Configuration.builtInSpeakersLabel
            if (root.model.portName === Settings.volumeInternalMicPortName)
                return Configuration.internalMicrophoneLabel
        }

        return root.model.name
    }
}
