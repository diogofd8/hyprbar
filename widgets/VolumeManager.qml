import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components
import qs.core as Core

import "volumemanager" as VolumeUI

Pane {
    id: root
    signal dismissRequested()

    readonly property string panelBackgroundColor: Settings.colors.bgMain
    readonly property real targetImplicitHeight: panelContent.implicitHeight + root.topPadding + root.bottomPadding

    // 0 shows physical input/output devices; 1 shows application streams.
    property int activeMixerMode: 0

    padding: WidgetConfiguration.dropDownWindowPadding
    implicitHeight: root.targetImplicitHeight
    clip: true

    background: Rectangle {
        color: Qt.alpha(root.panelBackgroundColor, Settings.colors.bgOpacity)

        border.width: 1
        border.color: Qt.alpha(Settings.colors.fgMain, Settings.colors.hoverOpacity)

        // Hide the top border
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: parent.border.width
            color: root.panelBackgroundColor
        }
    }

    contentItem: ColumnLayout {
        id: panelContent

        // ────── Top Row ──────
        ColumnLayout {
            id: headerContainer
            spacing: WidgetConfiguration.mainRowPadding

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: WidgetConfiguration.mainRowPadding
                Layout.rightMargin: WidgetConfiguration.mainRowPadding
                spacing: WidgetConfiguration.mainRowHSpacing

                Item {
                    id: volumeMixer
                    Layout.topMargin: WidgetConfiguration.hexBtnVPadding
                    Layout.bottomMargin: WidgetConfiguration.hexBtnVPadding
                    implicitWidth: mixerToggler.implicitWidth
                    implicitHeight: mixerToggler.implicitHeight

                    Rectangle {
                        id: volumeMixerBg

                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                            leftMargin: mixerDevicesBtn.width / 2
                            rightMargin: mixerStreamsBtn.width / 2
                        }

                        color: Settings.colors.bgTint2
                    }

                    RowLayout {
                        id: mixerToggler
                        anchors.fill: parent
                        spacing: WidgetConfiguration.hexBtnSpacing

                        HexagonButton {
                            id: mixerDevicesBtn

                            enabled: true // PLACEBO
                            bgFill: root.activeMixerMode === 0
                                ? Settings.colors.accentMain : Settings.colors.bgTint3
                            glyph: VolumeUI.Configuration.volMixerMode[0].icon
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: root.activeMixerMode === 0
                                ? Settings.colors.fgDark : Settings.colors.fgMain
                            glyphHorizontalOffset: -0.5
                            onLeftClicked: root.activeMixerMode = 0
                        }

                        HexagonButton {
                            id: mixerStreamsBtn

                            bgFill: root.activeMixerMode === 1
                                ? Settings.colors.accentMain : Settings.colors.bgTint3
                            glyph: VolumeUI.Configuration.volMixerMode[1].icon
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: root.activeMixerMode === 1
                                ? Settings.colors.fgDark : Settings.colors.fgMain
                            glyphHorizontalOffset: -0.5
                            onLeftClicked: root.activeMixerMode = 1
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    id: outputVolumeToggler
                    Layout.alignment: Qt.AlignVCenter
                    spacing: WidgetConfiguration.hexSwitchSpacing

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: outputGlyph.implicitWidth
                        implicitHeight: outputSwitch.implicitHeight

                        Glyph {
                            id: outputGlyph
                            anchors.horizontalCenter: parent.horizontalCenter
                            icon: VolumeUI.Configuration.outputMuteState[
                                Core.Audio.sink.muted ? 1 : 0]
                            iconSize: WidgetConfiguration.widgetMainIconSz
                            iconColor: Settings.colors.fgMain
                            useMetrics: true
                            verticalOffset: 0
                        }
                    }

                    HexagonSwitch {
                        id: outputSwitch
                        actionable: Core.Audio.sink.available
                        checked: !Core.Audio.sink.muted
                        onClicked: Core.Audio.toggleMute()

                        backgroundColor: root.panelBackgroundColor
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    id: inputVolumeToggler
                    Layout.alignment: Qt.AlignVCenter
                    spacing: WidgetConfiguration.hexSwitchSpacing

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: inputGlyph.implicitWidth
                        implicitHeight: inputSwitch.implicitHeight

                        Glyph {
                            id: inputGlyph
                            anchors.horizontalCenter: parent.horizontalCenter
                            icon: VolumeUI.Configuration.inputMuteState[
                                Core.Audio.source.muted ? 1 : 0]
                            iconSize: WidgetConfiguration.widgetMainIconSz
                            iconColor: Settings.colors.fgMain
                            useMetrics: true
                            verticalOffset: 0
                        }
                    }

                    HexagonSwitch {
                        id: inputSwitch
                        actionable: Core.Audio.source.available
                        checked: !Core.Audio.source.muted
                        onClicked: Core.Audio.toggleSourceMute()

                        backgroundColor: root.panelBackgroundColor
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                SquaredButton {
                    glyph: VolumeUI.Configuration.volumeSettingsIcon
                    glyphSize: WidgetConfiguration.widgetMainIconSz
                    useMetrics: true
                    color: Settings.colors.fgMain

                    onLeftClicked: {
                        VolumeUI.VolumeActions.volumeManager()
                        root.dismissRequested()
                    }
                }
            }

            // ────── Separator ──────
            Separator {
                Layout.fillWidth: true
                Layout.topMargin: 1
                Layout.bottomMargin: WidgetConfiguration.mainRowVMargin
                color: Settings.colors.bgTint4
            }
        }


        // ────── Volume Entries ──────
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: VolumeUI.Configuration.contentWidth
            implicitHeight: Math.min(contents.implicitHeight, WidgetConfiguration.rowContentMaxHeight)
            contentWidth: width
            contentHeight: contents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Item {
                id: contents
                width: scroll.width
                implicitHeight: root.activeMixerMode === 0 ? devicePage.implicitHeight : streamPage.implicitHeight
                clip: true

                Item {
                    id: devicePage
                    width: contents.width
                    implicitHeight: deviceSections.implicitHeight
                    x: (0 - root.activeMixerMode) * contents.width

                    Behavior on x {
                        NumberAnimation {
                            duration: VolumeUI.Configuration.transitionMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    ColumnLayout {
                        id: deviceSections
                        width: parent.width
                        spacing: WidgetConfiguration.sectionVSpacing

                        ColumnLayout {
                            id: outputVolumeSection

                            Layout.fillWidth: true
                            visible: true
                            spacing: WidgetConfiguration.sectionContentVSpacing

                            Text {
                                text: "OUTPUT DEVICES"
                                color: Settings.colors.fgMain
                                font.family: Settings.labelFontFamily
                                font.bold: true
                                font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                            }

                            Repeater {
                                model: Core.Audio.outputDeviceModel
                                delegate: VolumeUI.DeviceVolumeEntry {
                                    Layout.fillWidth: true

                                    onDismissRequested: root.dismissRequested()
                                }
                            }
                        }

                        ColumnLayout {
                            id: inputVolumeSection

                            Layout.fillWidth: true
                            visible: true
                            spacing: WidgetConfiguration.sectionContentVSpacing

                            Text {
                                Layout.bottomMargin: 4

                                text: "INPUT DEVICES"
                                color: Settings.colors.fgMain
                                font.family: Settings.labelFontFamily
                                font.bold: true
                                font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                            }

                            Repeater {
                                model: Core.Audio.inputDeviceModel
                                delegate: VolumeUI.DeviceVolumeEntry {
                                    Layout.fillWidth: true

                                    onDismissRequested: root.dismissRequested()
                                }
                            }
                        }
                    }
                }

                Item {
                    id: streamPage
                    width: contents.width
                    implicitHeight: appVolumeSection.implicitHeight
                    x: (1 - root.activeMixerMode) * contents.width

                    Behavior on x {
                        NumberAnimation {
                            duration: WidgetConfiguration.transitionMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    ColumnLayout {
                        id: appVolumeSection
                        width: parent.width
                        spacing: WidgetConfiguration.sectionContentVSpacing

                    Text {
                        text: "APPLICATIONS"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                    }

                        Repeater {
                            model: Core.Audio.applicationModel
                            delegate: VolumeUI.AppVolumeEntry {
                                Layout.fillWidth: true

                                onDismissRequested: root.dismissRequested()
                            }
                        }

                        Text {
                            visible: Core.Audio.applicationModel.count === 0
                            text: "No applications playing"
                            color: Settings.colors.fgMain
                            opacity: 0.7
                            font.family: Settings.labelFontFamily
                            font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                        }
                    }
                }
            }
        }
    }
}
