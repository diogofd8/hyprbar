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

    readonly property bool isKeyboard: root.model.kind === "keyboard"
    readonly property bool canChange: root.model.available && !root.model.busy
        && (root.model.kind !== "external" || !Core.Backlight.ddcBusy)
    readonly property bool commitOnRelease: root.model.kind !== "internal"

    function requestValue(value) {
        Core.Backlight.setEntryBrightness(root.model.kind, root.model.bus,
            Math.round(value))
    }

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

        Glyph {
            id: entryGlyph
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: WidgetConfiguration.entryIconHPadding
            Layout.rightMargin: WidgetConfiguration.entryIconHPadding

            icon: root.isKeyboard ? Configuration.keyboardEntryIcon : Configuration.displayEntryIcon
            iconSize: WidgetConfiguration.entryRowMainIconSz
            useMetrics: false
        }

        ColumnLayout {
            spacing: WidgetConfiguration.entryRowVSpacing

            // ────── Main Row ──────
            RowLayout {
                id: mainRow

                Layout.fillWidth: true
                Layout.preferredHeight: WidgetConfiguration.entryRowMainIconSz
                spacing: WidgetConfiguration.entryTitleRowHSpacing

                Text {
                    id: displayEntryName
                    Layout.fillWidth: true

                    text: BrightnessActions.entryName(root.model)
                    elide: Text.ElideRight
                    color: Settings.colors.foreground.main
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
                }
            }

            // ────── Extended Row ──────
            Loader {
                id: sliderLoader
                Layout.fillWidth: true
                Layout.topMargin: WidgetConfiguration.sliderExtraSpacing
                Layout.bottomMargin: WidgetConfiguration.sliderExtraSpacing

                sourceComponent: root.isKeyboard ? keyboardSliderComponent : screenSliderComponent
            }
        }
    }

    Component {
        id: screenSliderComponent

        RowLayout {
            id: backgroundClip2
            readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: backgroundClip2 }

            clip: true
            spacing: WidgetConfiguration.entryExtendedRowHSpacing

            HexagonSlider {
                Layout.fillWidth: true

                from: 0
                to: 100
                value: root.model.value
                actionable: root.canChange
                bgFill: Settings.colors.background.tint2

                onMoved: {
                    if (!root.commitOnRelease)
                        root.requestValue(value)
                }
                onPressedChanged: {
                    if (!pressed && root.commitOnRelease
                            && Math.round(value) !== root.model.value)
                        root.requestValue(value)
                }
            }

            Percentage {
                height: sliderLoader.height
                value: root.model.value
                fontFamily: Settings.labelFontFamily
                fontSize: WidgetConfiguration.entryRowDefaultFontSz
                verticalOffset: 0
            }
        }
    }

    Component {
        id: keyboardSliderComponent

        RowLayout {
            id: backgroundClip3
            readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: backgroundClip3 }

            clip: true
            spacing: WidgetConfiguration.entryExtendedRowHSpacing

            HexagonDiscreteSlider {
                Layout.fillWidth: true

                stepCount: root.model.max + 1
                value: root.model.value
                actionable: root.canChange
                bgFill: Settings.colors.background.tint2

                onPressedChanged: {
                    if (!pressed && Math.round(value) !== root.model.value)
                        root.requestValue(value)
                }
            }

            Item {
                id: fuzzyBrightness
                // Percentage is measured with 4 characters, so we use the same width for the fuzzy brightness text
                width: 4 * fontMetrics.averageCharacterWidth
                height: parent.height

                Row {
                    id: fuzzyContent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: WidgetConfiguration.entryExtendedRowHSpacing

                    Circle {
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: root.model.available ? 1 : 0
                        diameter: Configuration.keyboardBrightnessIndicatorSz
                        color: keyboardModeIconColor()
                    }

                    Text {
                        text: keyboardModeText()
                        color: Settings.colors.foreground.main
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                    }
                }

                FontMetrics {
                    id: fontMetrics

                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                }
            }
        }
    }

    // ────── Row logic ──────
    function keyboardModeText() {
        if (!root.model.available)
            return ""

        switch (root.model.value) {
            case 0: return "LO"
            case 1: return "MD"
            case 2: return "HI"
            default: return ""
        }
    }

    function keyboardModeIconColor(): color {
        const strength = Math.min(1, 0.2 + 0.4 * root.model.value)
        return Qt.tint(Settings.colors.background.tint2,
            Qt.alpha(Settings.colors.foreground.main, strength))
    }
}
