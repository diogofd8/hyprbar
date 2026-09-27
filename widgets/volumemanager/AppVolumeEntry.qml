import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell.Widgets

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

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            implicitWidth: Configuration.applicationIconSize
            implicitHeight: Configuration.applicationIconSize

            IconImage {
                id: volEntryIcon
                anchors.centerIn: parent
                implicitSize: Configuration.applicationIconSize
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
                iconSize: Configuration.applicationIconSize
                useMetrics: false
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

                    text: root.model.name
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.volEntryNameFontSize
                }

                Text {
                    visible: !root.model.hasStream
                    text: "Idle"
                    color: Settings.colors.fgMain
                    opacity: 0.7
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.subTextFontSize
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
                    enabled: root.model.hasStream
                    opacity: enabled ? 1 : 0.4

                    glyph: root.model.muted
                        ? Configuration.outputMuteState[1]
                        : Configuration.outputMuteState[0]
                    glyphSize: Configuration.secondaryButtonSize
                    color: Settings.colors.fgMain

                    onLeftClicked: Core.Audio.setEntryMuted(
                        root.model.id, !root.model.muted)
                }

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
                    Layout.leftMargin: Configuration.volEntryRowSpacing
                    height: parent.height

                    value: String(root.model.value)
                    visible: root.model.hasStream

                    fontFamily: Settings.labelFontFamily
                    fontSize: Configuration.volEntryNameFontSize
                }
            }
        }
    }
}
