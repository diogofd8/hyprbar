import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components
import qs.core as Core
import qs.widgets as Widgets

AbstractButton {
    id: root

    required property var day
    required property string todayDate
    property var service: Core.WeatherParse
    property bool selected: false
    property color bgFill: Settings.colors.bgTint1

    padding: Configuration.weatherEntryPadding
    hoverEnabled: true

    background: Rectangle {
        color: root.selected ? Settings.colors.bgTint2 : root.bgFill

        Rectangle {
            anchors.fill: parent
            color: Settings.colors.fgMain
            opacity: Settings.colors.hoverOpacity
            visible: root.hovered
        }
    }

    contentItem: ColumnLayout {
        spacing: Configuration.weatherEntryVSpacing

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.dayLabel()
            color: Settings.colors.fgMain
            font.family: Settings.labelFontFamily
            font.pixelSize: Widgets.WidgetConfiguration.sectionRowLabelFontSz
            font.bold: root.selected ? true : false
        }

        Glyph {
            Layout.alignment: Qt.AlignHCenter
            icon: root.day.icon
            iconSize: Configuration.weatherEntryIconSize
            iconColor: Configuration.weatherGlyphColor(root.day.icon, root.service.current.isDay)
            useMetrics: false
        }

        ColumnLayout {
            id: tempRange
            spacing: -Configuration.weatherEntryTempRangeSpacingOffset
            Layout.alignment: Qt.AlignHCenter

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.service.formatTemperature(root.day.temperatureMax ?? NaN)
                font.pixelSize: Configuration.weatherEntryTempMaxSz
                font.family: Settings.labelFontFamily
                font.bold: true
                color: Configuration.weatherFontColor.temp_high
            }

            // ────── Separator ──────
            Separator {
                Layout.bottomMargin: Configuration.weatherEntryTempRangeSpacingOffset
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: Configuration.weatherEntrySeparatorWidth
                color: Settings.colors.bgTint4
                opacity: Settings.colors.dimOpacity
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.service.formatTemperature(root.day.temperatureMin ?? NaN)
                font.pixelSize: Configuration.weatherEntryTempMinSz
                font.family: Settings.labelFontFamily
                color: Configuration.weatherFontColor.temp_low
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Configuration.weatherEntryHSpacing

            Glyph {
                Layout.alignment: Qt.AlignVCenter
                icon: Configuration.weatherIcon.precipitation
                iconSize: Configuration.weatherEntryIndicatorIconSz
                useMetrics: false
                color: Configuration.weatherFontColor.rain_title
            }

            ValueUnit {
                value: root.day.precipitationProbability ?? NaN
                unit: "%"
                decimals: Configuration.weatherMeasurementDecimals
                unitSpacingRatio: Configuration.weatherValueUnitSpacingRatio
                unknownText: root.service.unknownText
                fontSize: Configuration.weatherEntryFontSz
                color: Configuration.weatherFontColor.rain_title
            }
        }
    }

    // ────── Helper Functions ──────
    function dayLabel(): string {
        if (root.day.date === root.todayDate)
            return "TODAY"

        return root.service.formatDayLabel(root.day.date)
    }
}
