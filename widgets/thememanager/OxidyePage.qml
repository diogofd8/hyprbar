import QtQuick
import QtQuick.Layouts

import qs
import qs.components
import qs.core as Core
import qs.widgets

ColumnLayout {
    id: root
    spacing: 0

    property string draftSeed: ""
    readonly property bool canApply: picker.valid && Core.ThemeControl.canApplyAccent && !Core.ThemeControl.busy
        && (Core.SystemPalette.source !== "fixed"
            || Core.ThemeControl.normalizeSeed(picker.selectedSeed) !== Core.ThemeControl.normalizeSeed(Core.SystemPalette.accentSeed))

    function selectSeed(seed: string): void {
        draftSeed = seed
        // Reselecting a saved seed must also reset the sliders when the source
        // string already matches; in that case onSourceSeedChanged does not fire.
        picker.resetFromSource()
    }

    Component.onCompleted: selectSeed(Core.SystemPalette.fixedSeed)

    Connections {
        target: Core.SystemPalette
        function onFixedSeedChanged(): void { root.selectSeed(Core.SystemPalette.fixedSeed) }
    }

    Connections {
        target: Core.ThemeControl
        function onAccentApplied(seed: string): void { root.selectSeed(seed) }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Configuration.themePageMarginX
        Layout.rightMargin: Configuration.themePageMarginX
        spacing: WidgetConfiguration.mainRowHSpacing

        Text {
            text: "ACCENT SPECTRUM"
            font.family: Settings.labelFontFamily
            font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
            font.bold: true
            color: Settings.colors.foreground.main
        }

        Item {
            Layout.fillWidth: true
        }

        ChevronButton {
            id: applyBtn
            bgFill: picker.previewColor
            hoverOpacity: Settings.colors.background.hoverOpacityStrong
            enabled: root.canApply
            opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity

            implicitHeight: applyRow.implicitHeight + Configuration.applyBtnPaddingY
            contentLeftPadding: Configuration.applyBtnPaddingX
            contentRightPadding: Configuration.applyBtnPaddingX
            leftCap: Core.ChevronGeometry.Cap.Point
            rightCap: Core.ChevronGeometry.Cap.Point

            onLeftClicked: Core.ThemeControl.applyAccent(picker.selectedSeed)

            RowLayout {
                id: applyRow
                spacing: Configuration.applyBtnHSpacing

                Glyph {
                    id: applyIcon

                    icon: Configuration.applyIcon
                    iconSize: Configuration.btnsIconSz
                    color: Core.Oklch.contrastInk(picker.previewColor)
                }

                Text {
                    id: applyText

                    text: "APPLY"
                    color: Core.Oklch.contrastInk(picker.previewColor)
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Settings.smallCapsFontSize
                    font.weight: Font.Bold
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    BackgroundRectangle {
        Layout.fillWidth: true
        height: picker.implicitHeight + Configuration.colorSelectorPaddingY
        Layout.leftMargin: Configuration.themePageMarginX
        Layout.rightMargin: Configuration.themePageMarginX
        color: Settings.colors.background.tint1
        border.width: Configuration.pickerContainerBorderSz
        border.color: Settings.colors.background.tint2

        HsvColorPicker {
            id: picker
            objectName: "accentPicker"
            anchors.centerIn: parent
            width: parent.width - Configuration.colorSelectorPaddingX
            sourceSeed: root.draftSeed
            enabled: valid && Core.ThemeControl.canApplyAccent && !Core.ThemeControl.busy
        }
    }

    Item {
        Layout.fillHeight: true
    }

    BackgroundRectangle {
        Layout.fillWidth: true
        height: savedColors.implicitHeight + Configuration.savedColorsPaddingY
        color: Settings.colors.background.tint1

        BackgroundRectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Configuration.pickerContainerBorderSz
            color: Settings.colors.background.tint2
        }

        RowLayout {
            id: savedColors
            anchors.centerIn: parent
            width: parent.width - 2 * Configuration.themePageMarginX
            spacing: 0

            RowLayout {
                id: savedColorsLabel
                spacing: WidgetConfiguration.mainRowHSpacing

                Glyph {
                    icon: Configuration.savedColorsIcon
                    iconSize: Configuration.btnsIconSz
                }

                Text {
                    text: "SAVED COLORS"
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                    font.bold: true
                    color: Settings.colors.foreground.main
                }
            }

            Item { Layout.fillWidth: true }

            Flickable {
                id: savedSpectraScroll
                objectName: "savedSpectraScroll"
                // Pad for the hovered swatch's outer hexagon at its
                // widest points, independently of the add button's size.
                readonly property real hoverRoom: {
                    const half = Configuration.colorBtnSz / Math.sqrt(3)
                    const ring = 2 * Configuration.savedColorBtnHoverBorder / Math.sqrt(3)
                    return Math.ceil((half + ring) * Configuration.savedColorHoverScale - half)
                }
                Layout.fillWidth: true
                Layout.maximumWidth: contentWidth
                implicitWidth: contentWidth
                implicitHeight: Configuration.colorBtnSz + 2 * hoverRoom
                contentHeight: height
                contentWidth: spectrumRow.width + 2 * hoverRoom
                clip: true
                interactive: contentWidth > width
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                // There is no scrollbar: either wheel axis scrolls the row
                // sideways, one swatch per notch.
                function scrollBy(event): void {
                    const pixels = event.pixelDelta.x || event.pixelDelta.y
                    const notches = (event.angleDelta.x || event.angleDelta.y) / 120
                    if (!pixels && !notches) {
                        event.accepted = false
                        return
                    }
                    const distance = pixels || notches * (saveSpectrumButton.implicitWidth + spectrumRow.spacing)
                    cancelFlick()
                    contentX = Math.max(0, Math.min(contentWidth - width, contentX - distance))
                    event.accepted = true
                }

                WheelHandler {
                    parent: savedSpectraScroll
                    target: null
                    enabled: savedSpectraScroll.interactive
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => savedSpectraScroll.scrollBy(event)
                }

                Row {
                    id: spectrumRow
                    x: savedSpectraScroll.hoverRoom
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: WidgetConfiguration.hexBtnSpacing

                    Repeater {
                        model: Core.ThemeControl.savedSpectra

                        ColorButton {
                            required property string modelData
                            objectName: "savedSpectrum-" + modelData
                            text: "Select " + modelData
                            selected: modelData === Core.ThemeControl.normalizeSeed(picker.selectedSeed)

                            sample: {
                                const seed = Core.Oklch.parse(modelData)
                                return Core.Oklch.displayColor(seed.lightness, seed.chroma, seed.hue)
                            }

                            enabled: Core.ThemeControl.canApplyAccent && !Core.ThemeControl.busy
                            onClicked: root.selectSeed(modelData)
                            onRightClicked: Core.ThemeControl.removeSpectrum(modelData)
                        }
                    }
                }
            }

            Separator {
                objectName: "savedSpectraSeparator"
                orientation: Qt.Vertical
                Layout.preferredHeight: Configuration.colorBtnSz
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Configuration.savedColorsSeparatorPaddingLeft
                Layout.rightMargin: Configuration.savedColorsSeparatorPaddingRight
                color: Settings.colors.background.tint4
            }

            AddButton {
                id: saveSpectrumButton
                objectName: "saveSpectrumButton"
                text: "Save selected spectrum"
                enabled: picker.valid && Core.ThemeControl.spectraWritable && !Core.ThemeControl.busy
                    && !Core.ThemeControl.savedSpectra.includes(Core.ThemeControl.normalizeSeed(picker.selectedSeed))
                onClicked: Core.ThemeControl.saveSpectrum(picker.selectedSeed)
            }
        }
    }
}