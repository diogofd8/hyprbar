import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components
import qs.core as Core

import "brightnessmanager" as BrightnessUI

Pane {
    id: root
    signal dismissRequested()

    readonly property string panelBackgroundColor: Settings.colors.bgMain
    readonly property real targetImplicitHeight: panelContent.implicitHeight + topPadding + bottomPadding

    padding: BrightnessUI.Configuration.widgetBoxPadding
    implicitHeight: targetImplicitHeight
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
        RowLayout {
            Layout.fillWidth: true
            spacing: BrightnessUI.Configuration.topBarPadding

            RowLayout {
                Layout.leftMargin: BrightnessUI.Configuration.topBarPadding
                Layout.alignment: Qt.AlignVCenter
                spacing: 5

                Glyph {
                    icon: BrightnessUI.Configuration.nightModeIcon
                    iconSize: BrightnessUI.Configuration.mainButtonSize
                    iconColor: Settings.colors.fgMain
                }

                HexagonSwitch {
                    actionable: Core.Backlight.nightLightLoaded && !Core.Backlight.nightLightBusy
                    checked: Core.Backlight.nightLightEnabled
                    backgroundColor: root.panelBackgroundColor
                    onClicked: BrightnessUI.BrightnessActions.toggleNightLight()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
            }

            Text {
                text: "TEMPERATURE:"
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: BrightnessUI.Configuration.subTextFontSize
            }

            Temperature {
                value: BrightnessUI.BrightnessActions.nightTemperatureText(Core.Backlight.nightLightEnabled, Core.Backlight.nightTemperature)
                visible: Core.Backlight.nightLightLoaded
                opacity: 0.7
                color: Core.Backlight.nightLightEnabled ? Settings.colors.accentAlert : Settings.colors.fgMain
                unit: "K"
                verticalOffset: 0
                fontFamily: Settings.labelFontFamily
                fontSize: BrightnessUI.Configuration.subTextFontSize
            }
        }

        // ────── Error Message ──────
        Text {
            Layout.fillWidth: true
            visible: Core.Backlight.nightLightError.length > 0
            text: Core.Backlight.nightLightError
            wrapMode: Text.WordWrap
            color: Settings.colors.accentError
            font.family: Settings.labelFontFamily
            font.pixelSize: BrightnessUI.Configuration.subTextFontSize
        }

        // ────── Separator ──────
        Separator {
            Layout.fillWidth: true
            Layout.topMargin: 1
            Layout.bottomMargin: BrightnessUI.Configuration.mainColumnGap
            color: Settings.colors.bgTint4
        }

        // ────── Brightness Entries ──────
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: BrightnessUI.Configuration.contentWidth
            implicitHeight: Math.min(contents.implicitHeight, BrightnessUI.Configuration.listMaxHeight)
            contentWidth: width
            contentHeight: contents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contents
                width: scroll.width
                spacing: BrightnessUI.Configuration.sectionSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: BrightnessUI.Configuration.brEntryRowSpacing

                    Text {
                        Layout.bottomMargin: 4

                        text: "SCREEN BRIGHTNESS"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: BrightnessUI.Configuration.columnLabelFontSize
                    }

                    Repeater {
                        model: Core.Backlight.screenEntryModel
                        delegate: BrightnessUI.BrightnessEntry {
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: Core.Backlight.screenError.length > 0
                        text: Core.Backlight.screenError
                        wrapMode: Text.WordWrap
                        color: Settings.colors.accentError
                        font.family: Settings.labelFontFamily
                        font.pixelSize: BrightnessUI.Configuration.subTextFontSize
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: BrightnessUI.Configuration.brEntryRowSpacing

                    Text {
                        Layout.bottomMargin: 4
                        text: "KEYBOARD BRIGHTNESS"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: BrightnessUI.Configuration.columnLabelFontSize
                    }

                    Repeater {
                        model: Core.Backlight.keyboardEntryModel
                        delegate: BrightnessUI.BrightnessEntry {
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: !Core.Backlight.keyboardAvailable
                            || Core.Backlight.keyboardError.length > 0
                        text: Core.Backlight.keyboardError
                            || "Keyboard backlight unavailable."
                        wrapMode: Text.WordWrap
                        color: Settings.colors.accentError
                        font.family: Settings.labelFontFamily
                        font.pixelSize: BrightnessUI.Configuration.subTextFontSize
                    }
                }
            }
        }
    }
}
