import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs
import qs.components
import qs.core as Core
import qs.widgets as Widgets

Pane {
    id: root

    property var service: Core.WeatherParse
    property string selectedDate: ""
    readonly property var forecast: root.service.daily
    readonly property var selectedDay: root.findSelectedDay()
    readonly property string todayDate: Qt.formatDateTime(clock.date, "yyyy-MM-dd")

    background: null
    // ────── Dimensioning ──────
    topPadding: Configuration.pagePadding - Widgets.WidgetConfiguration.dropDownWindowPadding
    bottomPadding: Configuration.pagePadding
    horizontalPadding: Configuration.pagePadding

    onForecastChanged: root.selectAvailableDay()
    Component.onCompleted: root.selectAvailableDay()

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    contentItem: ColumnLayout {
        id: pageLayout
        spacing: Configuration.weatherColumnVSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Configuration.weatherTitleRowHSpacing

            RowLayout {
                spacing: Configuration.weatherLocationFieldHSpacing
                Layout.leftMargin: Configuration.weatherLocationFieldHSpacing

                Circle {
                    Layout.alignment: Qt.AlignVCenter
                    diameter: Configuration.weatherLocationDotSize
                    color: root.service.lastError ? Settings.colors.foreground.error : Settings.colors.foreground.charging
                }

                Text {
                    text: root.service.location.label || root.service.unknownText
                    color: Settings.colors.foreground.main
                    font.family: Settings.labelFontFamily
                    font.bold: true
                    font.pixelSize: Configuration.weatherDefaultFontSz
                }
            }

            Circle {
                Layout.alignment: Qt.AlignVCenter
                diameter: Settings.separatorDotSize
                color: Settings.colors.foreground.muted
            }

            Text {
                text: root.updatedTime()
                color: Settings.colors.foreground.muted
                font.family: Settings.labelFontFamily
                font.pixelSize: Widgets.WidgetConfiguration.sectionRowLabelFontSz

            }

            Item {
                Layout.fillWidth: true
            }

            SquaredButton {
                id: weatherRefreshBtn

                enabled: !root.service.loading
                glyph: Configuration.weatherIcon.refresh
                glyphSize: Widgets.WidgetConfiguration.widgetMainIconSz
                useMetrics: true
                color: Settings.colors.foreground.main

                onLeftClicked: root.service.refresh()

                NumberAnimation on glyphRotation {
                    from: Configuration.weatherRefreshStartRotation
                    to: 0
                    duration: Motion.activitySpinMs
                    loops: Animation.Infinite
                    running: root.service.loading

                    onStopped: weatherRefreshBtn.glyphRotation = 0
                }
            }
        }

        WeatherCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            visible: root.selectedDay !== null
            service: root.service
            day: root.selectedDay
        }

        RowLayout {
            id: dailyForecast

            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Configuration.weatherEntriesHSpacing
            uniformCellSizes: true

            Repeater {
                model: root.forecast

                WeatherEntry {
                    required property var modelData

                    Layout.fillWidth: true
                    service: root.service
                    day: modelData
                    todayDate: root.todayDate
                    selected: root.selectedDay?.date === modelData.date

                    onClicked: root.selectedDate = modelData.date
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.forecast.length === 0
            text: root.emptyMessage()
            color: Settings.colors.foreground.muted
            font.family: Settings.labelFontFamily
            font.pixelSize: Widgets.WidgetConfiguration.sectionRowLabelFontSz

            wrapMode: Text.WordWrap
        }
    }

    // ────── Helper Functions ──────
    function findSelectedDay(): var {
        return root.forecast.find(day => day.date === root.selectedDate) ?? root.forecast[0] ?? null
    }

    function selectAvailableDay(): void {
        if (root.forecast.some(day => day.date === root.selectedDate))
            return

        const today = root.forecast.find(day => day.date === root.todayDate)
        root.selectedDate = today?.date ?? root.forecast[0]?.date ?? ""
    }

    function updatedTime(): string {
        const updated = root.service.lastUpdated
        return updated ? Qt.formatDateTime(updated, "HH:mm") : root.service.unknownText
    }

    function refreshHint(): string {
        if (root.service.loading)
            return "Refreshing weather…"

        return root.service.lastError || "Refresh weather"
    }

    function emptyMessage(): string {
        if (root.service.loading)
            return "Loading weather…"

        return root.service.lastError || "Weather unavailable"
    }
}
