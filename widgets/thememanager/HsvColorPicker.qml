import QtQuick
import QtQuick.Layouts

import qs
import qs.components
import qs.widgets
import qs.core as Core

// HSV sliders over an opaque OKLCH seed. An untouched seed is passed through
// exactly; once a slider moves, the HSV colour is converted to OKLCH.
ColumnLayout {
    id: root

    property string sourceSeed: ""
    readonly property var seed: Core.Oklch.parse(root.sourceSeed)
    readonly property bool valid: root.seed !== null
    // Retain the right-hand endpoint for the UI; colour conversion wraps it.
    readonly property real hue: hueSlider.value
    readonly property real saturation: saturationSlider.value
    readonly property real value: valueSlider.value
    // The slider values for sourceSeed, as the sliders actually hold them.
    property var sourceValues: [0, 0, 0]
    readonly property bool edited: hueSlider.value !== root.sourceValues[0] || saturationSlider.value !== root.sourceValues[1] || valueSlider.value !== root.sourceValues[2]

    readonly property string selectedSeed: {
        if (!root.valid) return ""
        if (!root.edited) return Core.Oklch.format(root.seed, root.seed.hue)
        const color = Core.Oklch.fromHsv(root.hue, root.saturation, root.value)
        return Core.Oklch.format(color, color.hue)
    }

    // Same path as SystemPalette.seedColor, so the sample matches the applied accent.
    readonly property color previewColor: {
        const selected = Core.Oklch.parse(root.selectedSeed)
        return selected ? Core.Oklch.displayColor(selected.lightness, selected.chroma, selected.hue) : "transparent"
    }

    spacing: Configuration.colorSelectorVSpacing
    opacity: root.enabled ? 1 : Settings.colors.foreground.disabledOpacity

    onSourceSeedChanged: root.resetFromSource()
    Component.onCompleted: root.resetFromSource()

    function resetFromSource(): void {
        const source = Core.Oklch.parse(root.sourceSeed)
        const hsv = source ? Core.Oklch.toHsv(source) : {hue: 0, saturation: 0, value: 0}
        hueSlider.value = hsv.hue
        saturationSlider.value = hsv.saturation
        valueSlider.value = hsv.value
        // Read back: sliders clamp and skip fuzzy-equal updates.
        root.sourceValues = [hueSlider.value, saturationSlider.value, valueSlider.value]
    }

    function channelColor(h: real, s: real, v: real): color {
        return Core.Oklch.hsvColor(h, s, v)
    }

    component ChannelLabel: Text {
        font.family: Settings.labelFontFamily
        font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
        color: Settings.colors.foreground.main
    }

    component Readout: ChannelLabel {
        id: readout
        horizontalAlignment: Text.AlignRight
        // A fixed width keeps the tracks still while the digits change.
        Layout.preferredWidth: widest.advanceWidth
        TextMetrics { id: widest; font: readout.font; text: "1.00" }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Configuration.colorSelectorHSpacing

        ChannelLabel {
            text: "H"
            font.bold: true
        }

        ColorChannelSlider {
            id: hueSlider
            objectName: "accentHueSlider"
            Layout.fillWidth: true
            to: 360
            thumbColor: root.previewColor
            Accessible.name: "Accent hue"
            // HSV is linear in sRGB between these 60° stops, so each track is exact.
            trackGradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.channelColor(0, root.saturation, root.value) }
                GradientStop { position: 1 / 6; color: root.channelColor(60, root.saturation, root.value) }
                GradientStop { position: 2 / 6; color: root.channelColor(120, root.saturation, root.value) }
                GradientStop { position: 3 / 6; color: root.channelColor(180, root.saturation, root.value) }
                GradientStop { position: 4 / 6; color: root.channelColor(240, root.saturation, root.value) }
                GradientStop { position: 5 / 6; color: root.channelColor(300, root.saturation, root.value) }
                GradientStop { position: 1; color: root.channelColor(360, root.saturation, root.value) }
            }
        }

        Readout {
            objectName: "accentHueReadout"
            text: root.valid ? Math.round(root.hue).toString() : "—"
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Configuration.colorSelectorHSpacing

        ChannelLabel {
            text: "S"
            font.bold: true
        }

        ColorChannelSlider {
            id: saturationSlider
            objectName: "accentSaturationSlider"
            Layout.fillWidth: true
            to: 1
            stepSize: 0.01
            thumbColor: root.previewColor
            Accessible.name: "Accent saturation"
            trackGradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.channelColor(root.hue, 0, root.value) }
                GradientStop { position: 1; color: root.channelColor(root.hue, 1, root.value) }
            }
        }

        Readout {
            objectName: "accentSaturationReadout"
            text: root.valid ? root.saturation.toFixed(2) : "—"
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Configuration.colorSelectorHSpacing

        ChannelLabel {
            text: "V"
            font.bold: true
        }

        ColorChannelSlider {
            id: valueSlider
            objectName: "accentValueSlider"
            Layout.fillWidth: true
            to: 1
            stepSize: 0.01
            thumbColor: root.previewColor
            Accessible.name: "Accent value"
            trackGradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.channelColor(root.hue, root.saturation, 0) }
                GradientStop { position: 1; color: root.channelColor(root.hue, root.saturation, 1) }
            }
        }

        Readout {
            objectName: "accentValueReadout"
            text: root.valid ? root.value.toFixed(2) : "—"
        }
    }
}
