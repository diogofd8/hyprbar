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

    readonly property bool isKeyboard: root.model.kind === "keyboard"
    readonly property bool canChange: root.model.available && !root.model.busy
        && (root.model.kind !== "external" || !Core.Backlight.ddcBusy)
    readonly property bool commitOnRelease: root.model.kind !== "internal"

    function requestValue(value) {
        Core.Backlight.setEntryBrightness(root.model.kind, root.model.bus,
            Math.round(value))
    }

    padding: Configuration.brEntryPadding
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
        spacing: Configuration.brEntryPadding

        Glyph {
            id: entryGlyph
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6
            Layout.rightMargin: 6

            icon: root.isKeyboard ? Configuration.keyboardEntryIcon : Configuration.displayEntryIcon
            iconSize: Configuration.mainButtonSize
            useMetrics: false
        }

        ColumnLayout {
            spacing: Configuration.brEntryPadding

            // ────── Main Row ──────
            RowLayout {
                Layout.fillWidth: true
                spacing: Configuration.brEntryPadding

                Text {
                    id: displayEntryName
                    Layout.fillWidth: true

                    text: BrightnessActions.entryName(root.model)
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.brNameFontSize
                }
            }

            // ────── Extended Row ──────
            RowLayout {
                Layout.fillWidth: true
                spacing: Configuration.brEntryPadding
                clip: true

                Loader {
                    id: sliderLoader
                    Layout.fillWidth: true
                    sourceComponent: root.isKeyboard ? keyboardSliderComponent : screenSliderComponent
                }

                Percentage {
                    Layout.leftMargin: Configuration.brEntryRowSpacing

                    visible: !root.isKeyboard
                    height: sliderLoader.height
                    value: root.model.value
                    fontFamily: Settings.labelFontFamily
                    fontSize: Configuration.brNameFontSize
                }

                Text {
                    Layout.leftMargin: Configuration.brEntryRowSpacing
                    Layout.rightMargin: Configuration.brEntryRowSpacing

                    visible: root.isKeyboard
                    text: root.model.available ? String(root.model.value) : " "
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.brNameFontSize
                }
            }
        }
    }

    Component {
        id: screenSliderComponent

        HexagonSlider {
            from: 0
            to: 100
            value: root.model.value
            actionable: root.canChange
            backgroundColor: Settings.colors.bgTint2

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
    }

    Component {
        id: keyboardSliderComponent

        HexagonDiscreteSlider {
            stepCount: root.model.max + 1
            value: root.model.value
            actionable: root.canChange
            backgroundColor: Settings.colors.bgTint2

            onPressedChanged: {
                if (!pressed && Math.round(value) !== root.model.value)
                    root.requestValue(value)
            }
        }
    }
}
