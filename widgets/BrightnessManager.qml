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

    padding: WidgetConfiguration.dropDownWindowPadding
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
        ColumnLayout {
            id: headerContainer
            spacing: WidgetConfiguration.mainRowPadding

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: WidgetConfiguration.mainRowPadding
                Layout.rightMargin: WidgetConfiguration.mainRowPadding
                spacing: WidgetConfiguration.mainRowHSpacing

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: WidgetConfiguration.hexSwitchSpacing

                    Glyph {
                        icon: BrightnessUI.Configuration.nightModeIcon
                        iconSize: WidgetConfiguration.widgetMainIconSz
                        iconColor: Settings.colors.fgMain
                    }

                    HexagonSwitch {
                        actionable: Core.Backlight.nightLightLoaded && !Core.Backlight.nightLightBusy
                        checked: Core.Backlight.nightLightEnabled
                        backgroundColor: root.panelBackgroundColor
                        onClicked: BrightnessUI.BrightnessActions.toggleNightLight()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "TEMPERATURE:"
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.widgetMainFontSz
                }

                Temperature {
                    value: BrightnessUI.BrightnessActions.nightTemperatureText(Core.Backlight.nightLightEnabled, Core.Backlight.nightTemperature)
                    visible: Core.Backlight.nightLightLoaded
                    opacity: 0.7
                    color: Core.Backlight.nightLightEnabled ? Settings.colors.accentAlert : Settings.colors.fgMain
                    unit: "K"
                    verticalOffset: 0
                    fontFamily: Settings.labelFontFamily
                    fontSize: WidgetConfiguration.widgetMainFontSz
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

        // ────── Error Message ──────
        Text {
            Layout.fillWidth: true
            visible: Core.Backlight.nightLightError.length > 0
            text: Core.Backlight.nightLightError
            wrapMode: Text.WordWrap
            color: Settings.colors.accentError
            font.family: Settings.labelFontFamily
            font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
        }

        // ────── Brightness Entries ──────
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: BrightnessUI.Configuration.contentWidth
            implicitHeight: Math.min(contents.implicitHeight, WidgetConfiguration.rowContentMaxHeight)
            contentWidth: width
            contentHeight: contents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contents
                width: scroll.width
                spacing: WidgetConfiguration.sectionVSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    Text {
                        text: "SCREEN BRIGHTNESS"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
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
                        font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    Text {
                        text: "KEYBOARD BRIGHTNESS"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
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
                        font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                    }
                }
            }
        }
    }
}
