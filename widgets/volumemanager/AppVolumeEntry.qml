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
    required property var model
    signal dismissRequested()

    // ────── Dimensioning ──────
    leftPadding: WidgetConfiguration.entryHPadding
    rightPadding: WidgetConfiguration.entryHPadding
    topPadding: WidgetConfiguration.entryVPadding
    bottomPadding: WidgetConfiguration.entryVPadding
    implicitHeight: mainContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    Behavior on implicitHeight {
        SmoothedAnimation {
            duration: WidgetConfiguration.transitionMs
            velocity: -1
            reversingMode: SmoothedAnimation.Eased
        }
    }

    background: Rectangle {
        color: Settings.colors.bgTint2
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
                Layout.topMargin: 0.5 * WidgetConfiguration.entryIconHPadding
                Layout.preferredHeight: WidgetConfiguration.entryRowMainIconSz
                spacing: WidgetConfiguration.entryTitleRowHSpacing

                Text {
                    id: volEntryName
                    Layout.fillWidth: true

                    text: root.model.name
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
                }

                Text {
                    visible: !root.model.hasStream
                    text: "Idle"
                    color: Settings.colors.fgMain
                    opacity: 0.7
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
                    enabled: root.model.hasStream
                    opacity: enabled ? 1 : 0.4

                    glyph: root.model.muted
                        ? Configuration.outputMuteState[1]
                        : Configuration.outputMuteState[0]
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

                        backgroundColor: Settings.colors.bgTint2

                        from: 0
                        to: 100
                        value: root.model.value

                        actionable: root.model.hasStream
                        opacity: actionable ? 1 : 0.4
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
