import QtQuick
import QtQuick.Layouts

import qs
import qs.components

RowLayout {
    id: root

    required property string coreName
    required property real stress
    required property real temperature

    spacing: Configuration.coreEntryHSpacing

    Text {
        id: nameLabel
        Layout.alignment: Qt.AlignVCenter

        text: root.coreName
        font.family: Settings.labelFontFamily
        font.pixelSize: Configuration.coreEntryFontSz
        font.bold: true
        color: Settings.colors.foreground.main
    }

    ColumnLayout {
        id: gauges
        Layout.fillWidth: false
        Layout.alignment: Qt.AlignVCenter
        spacing: Configuration.coreEntryGaugesVSpacing

        BackgroundRectangle {
            id: stressTrack
            Layout.fillWidth: true
            Layout.minimumHeight: implicitHeight
            Layout.maximumHeight: implicitHeight
            implicitWidth: Configuration.coreEntryGaugeWidth
            implicitHeight: Configuration.coreEntryTemperatureGaugeHeight * Configuration.coreEntryGaugeStressTempRatio
            color: Settings.colors.background.tint1
            opacity: Settings.colors.background.dimOpacity

            Rectangle {
                width: parent.width * root.gaugeProgress(root.stress, 100)
                height: parent.height
                color: Settings.colors.background.accent
                opacity: Settings.colors.background.dimOpacity
            }
        }

        BackgroundRectangle {
            id: temperatureTrack
            Layout.fillWidth: true
            Layout.minimumHeight: implicitHeight
            Layout.maximumHeight: implicitHeight
            implicitWidth: Configuration.coreEntryGaugeWidth
            implicitHeight: Configuration.coreEntryTemperatureGaugeHeight
            color: Settings.colors.background.tint1
            opacity: Settings.colors.background.dimOpacity

            Rectangle {
                width: parent.width * root.gaugeProgress(root.temperature, Configuration.cpuGaugeTemperatureMaxValue)
                height: parent.height
                color: Settings.colors.background.tint4
                opacity: Settings.colors.background.dimOpacity
            }
        }
    }

    RowLayout {
        id: cpuLabels
        Layout.fillWidth: false
        spacing: Configuration.coreEntryLabelHSpacing

        Text {
            id: temperatureLabel
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: valueMetrics.advanceWidth("99°C")

            text: root.valueText(root.temperature, "°C")
            horizontalAlignment: Text.AlignRight
            font.family: Settings.labelFontFamily
            font.pixelSize: Configuration.coreEntryFontSz
            color: Settings.colors.foreground.main
            opacity: Settings.colors.foreground.dimOpacity
        }

        Percentage {
            id: stressLabel
            Layout.alignment: Qt.AlignVCenter

            value: Math.trunc(root.stress)
            fontFamily: Settings.labelFontFamily
            fontSize: Configuration.coreEntryFontSz
            verticalOffset: 0
            color: Settings.colors.foreground.accent
        }
    }

    FontMetrics {
        id: valueMetrics
        font.family: Settings.labelFontFamily
        font.pixelSize: Configuration.coreEntryFontSz
    }

    // ────── Helper Functions ──────
    function gaugeProgress(value: real, maximum: real): real {
        if (!Number.isFinite(value) || maximum <= 0)
            return 0
        return Math.max(0, Math.min(1, value / maximum))
    }

    function valueText(value: real, unit: string): string {
        return Number.isFinite(value) ? Math.round(value) + unit : "—"
    }
}
