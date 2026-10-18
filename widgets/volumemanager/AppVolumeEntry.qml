import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell.Widgets

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

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: WidgetConfiguration.entryIconHPadding
            Layout.rightMargin: WidgetConfiguration.entryIconHPadding

            IconImage {
                id: volEntryIcon
                anchors.centerIn: parent
                implicitSize: WidgetConfiguration.entryRowMainIconSz
                source: root.model.iconSource
                visible: source.toString() !== "" && status !== Image.Error

                // Render at twice the display size, then filter down for smoother edges.
                backer.sourceSize: Qt.size(32, 32)
                mipmap: true
            }

            Glyph {
                anchors.centerIn: parent
                visible: !volEntryIcon.visible
                icon: Configuration.applicationFallbackIcon
                iconSize: WidgetConfiguration.entryRowMainIconSz
                useMetrics: false
            }
        }

        ColumnLayout {
            spacing: WidgetConfiguration.entryRowVSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: WidgetConfiguration.entryRowMainIconSz
                spacing: WidgetConfiguration.entryTitleRowHSpacing

                Text {
                    id: volEntryName
                    Layout.fillWidth: true

                    text: root.model.name
                    elide: Text.ElideRight
                    color: Settings.colors.foreground.main
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
                }

                Text {
                    visible: !root.model.hasStream
                    text: "Idle"
                    color: Settings.colors.foreground.muted

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
                    enabled: root.model.hasStream
                    opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity

                    glyph: root.model.muted
                        ? Configuration.outputMutedIcon
                        : Configuration.outputUnmutedIcon
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

                        bgFill: Settings.colors.background.tint2

                        from: 0
                        to: 100
                        value: root.model.value

                        actionable: root.model.hasStream
                        opacity: actionable ? 1 : Settings.colors.foreground.disabledOpacity
                        stepSize: 1
                        snapMode: Controls.Slider.SnapAlways

                        onMoved: Core.Audio.setEntryVolume(root.model.id, value)
                    }

                    Percentage {
                        height: parent.height

                        value: String(root.model.value)
                        visible: root.model.hasStream

                        fontFamily: Settings.labelFontFamily
                        fontSize: WidgetConfiguration.entryRowDefaultFontSz
                    }
                }
            }
        }
    }
}
