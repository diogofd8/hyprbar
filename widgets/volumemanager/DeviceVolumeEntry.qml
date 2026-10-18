import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import qs
import qs.components
import qs.widgets
import qs.core as Core

Controls.Pane {
    id: root

    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }
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

    background: BackgroundRectangle {
        color: Settings.colors.background.tint2
    }

    contentItem: RowLayout {
        id: mainContent
        spacing: WidgetConfiguration.entryHPadding

        GlyphButton {
            id: volEntryBtn
            enabled: root.model.canSelect
            opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: WidgetConfiguration.entryIconHPadding
            Layout.rightMargin: WidgetConfiguration.entryIconHPadding

            icon: root.model.isDefault
                ? Configuration.deviceSelectedIcon
                : Configuration.deviceUnselectedIcon
            iconSize: WidgetConfiguration.entryRowMainIconSz
            useMetrics: false
            iconColor: root.model.isDefault
                ? Settings.colors.foreground.accent : Settings.colors.foreground.main

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
                    color: Settings.colors.foreground.main
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
                    color: Settings.colors.foreground.main

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
                        ? (root.model.muted
                            ? Configuration.inputMutedIcon : Configuration.inputUnmutedIcon)
                        : (root.model.muted
                            ? Configuration.outputMutedIcon : Configuration.outputUnmutedIcon)
                    glyphSize: WidgetConfiguration.widgetSecondaryIconSz
                    color: Settings.colors.foreground.main

                    onLeftClicked: Core.Audio.setEntryMuted(
                        root.model.id, !root.model.muted)
                }

                RowLayout {
                    id: volumeSliderContainer

                    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: volumeSliderContainer }
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
                        bgFill: Settings.colors.background.tint2

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
