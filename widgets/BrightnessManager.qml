import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components
import qs.core as Core

import "brightnessmanager" as BrightnessUI

Pane {
    id: root

    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }

    readonly property string panelBackgroundColor: Settings.colors.background.main

    padding: WidgetConfiguration.dropDownWindowPadding
    implicitHeight: panelContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    // PopoutHost draws the panel background shared by every widget. Null, not
    // omitted, so the Controls style doesn't add a default one.
    background: null

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
                        iconColor: Settings.colors.foreground.main
                    }

                    HexagonSwitch {
                        actionable: Core.Backlight.nightLightLoaded && !Core.Backlight.nightLightBusy
                        checked: Core.Backlight.nightLightEnabled
                        bgFill: root.panelBackgroundColor
                        onClicked: BrightnessUI.BrightnessActions.toggleNightLight()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "TEMPERATURE:"
                    color: Settings.colors.foreground.main
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.widgetMainFontSz
                }

                Temperature {
                    value: BrightnessUI.BrightnessActions.nightTemperatureText(Core.Backlight.nightLightEnabled, Core.Backlight.nightTemperature)
                    visible: Core.Backlight.nightLightLoaded
                    color: Core.Backlight.nightLightEnabled
                        ? Qt.tint(Settings.colors.background.main, Qt.alpha(Settings.colors.foreground.alert, Settings.colors.foreground.dimOpacity))
                        : Settings.colors.foreground.muted
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
                color: Settings.colors.background.tint4
            }
        }

        // ────── Error Message ──────
        Text {
            Layout.fillWidth: true
            visible: Core.Backlight.nightLightError.length > 0
            text: Core.Backlight.nightLightError
            wrapMode: Text.WordWrap
            color: Settings.colors.foreground.error
            font.family: Settings.labelFontFamily
            font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
        }

        // ────── Brightness Entries ──────
        Flickable {
            id: scroll

            readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: scroll }
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
                        color: Settings.colors.foreground.main
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
                        color: Settings.colors.foreground.error
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    Text {
                        text: "KEYBOARD BRIGHTNESS"
                        color: Settings.colors.foreground.main
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
                        color: Settings.colors.foreground.error
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                    }
                }
            }
        }
    }
}
