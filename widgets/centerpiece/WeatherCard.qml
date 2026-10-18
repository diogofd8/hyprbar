import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components
import qs.core as Core
import qs.widgets as Widgets

Pane {
    id: root

    required property var day
    property var service: Core.WeatherParse
    property color bgFill: Settings.colors.background.tint1
    readonly property bool hasWindDirection: root.service.isNumber(root.day?.windDirectionDominant)

    // ────── Dimensioning ──────
    leftPadding: Configuration.weatherCardPaddingX
    rightPadding: Configuration.weatherCardPaddingX
    topPadding: Configuration.weatherCardPaddingY
    bottomPadding: Configuration.weatherCardPaddingY

    background: BackgroundRectangle {
        color: root.bgFill
    }

    contentItem: GridLayout {
        id: cardGrid

        columns: 5
        columnSpacing: 0
        rowSpacing: 0
        uniformCellHeights: true

        // Cells absorb spare space; their contents keep their natural size.
        Item {
            id: conditionCell

            Layout.row: 0
            Layout.column: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: forecastIcon.implicitWidth
            implicitHeight: forecastIcon.implicitHeight

            Glyph {
                id: forecastIcon

                anchors.centerIn: parent

                icon: root.day?.icon ?? root.service.unknownIcon
                iconSize: Configuration.weatherConditionIconSize
                iconColor: Configuration.weatherGlyphColor(forecastIcon.icon, root.service.current.isDay)
                useMetrics: false
            }
        }

        Item {
            id: descriptionCell

            Layout.row: 0
            Layout.column: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: cardGrid.implicitWidth / 4
            implicitHeight: descriptionLabel.implicitHeight

            // Measure at the normal size so shrinking cannot undo its own trigger.
            Text {
                id: descriptionMeasure

                visible: false
                width: descriptionLabel.width
                text: descriptionLabel.text
                font.family: descriptionLabel.font.family
                font.bold: descriptionLabel.font.bold
                font.pixelSize: Configuration.weatherDefaultFontSz
                wrapMode: descriptionLabel.wrapMode
                maximumLineCount: descriptionLabel.maximumLineCount
                elide: descriptionLabel.elide
            }

            Text {
                id: descriptionLabel

                anchors.centerIn: parent
                width: parent.width - Configuration.weatherCardDescriptionPaddingX

                text: root.day?.description ?? root.service.unknownText
                color: Settings.colors.foreground.main
                font.family: Settings.labelFontFamily
                font.bold: true
                font.pixelSize: descriptionMeasure.truncated
                    ? Configuration.weatherCardDescriptionReducedFontSz
                    : Configuration.weatherDefaultFontSz

                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        Item {
            id: temperatureCell
            Layout.row: 1
            Layout.column: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: tempRange.implicitWidth
            implicitHeight: tempRange.implicitHeight

            ColumnLayout {
                id: tempRange
                spacing: -Configuration.weatherCardTempRangeSpacingOffset
                anchors.centerIn: parent

                Temperature {
                    id: highTemp
                    Layout.alignment: Qt.AlignCenter
                    value: root.service.formatTemperature(root.day?.temperatureMax ?? NaN)
                    fontSize: Configuration.weatherCardTempMaxFontSz
                    fontBold: true

                    color: Configuration.weatherFontColor.temp_high
                }

                // ────── Separator ──────
                Separator {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: highTemp.implicitWidth + Configuration.weatherCardTempRangeSpacerWidthOffset
                    color: Settings.colors.background.tint4
                    opacity: Settings.colors.background.dimOpacity
                }

                Temperature {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: Configuration.weatherCardTempRangeSpacingOffset
                    value: root.service.formatTemperature(root.day?.temperatureMin ?? NaN)
                    fontSize: Configuration.weatherCardTempMinFontSz

                    color: Configuration.weatherFontColor.temp_low
                }
            }
        }

        Item {
            id: dateCell

            Layout.row: 1
            Layout.column: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: dateContainer.implicitWidth
            implicitHeight: dateContainer.implicitHeight

            ColumnLayout {
                id: dateContainer
                spacing: Configuration.weatherCardDateSpacing
                anchors.centerIn: parent

                Text {
                    Layout.bottomMargin: -Configuration.weatherCardDateSpacingOffset
                    Layout.alignment: Qt.AlignHCenter
                    text: root.service.formatDayLabel(root.day?.date ?? "")
                    color: Settings.colors.foreground.main
                    font.family: Settings.labelFontFamily
                    font.bold: true
                    font.pixelSize: Configuration.weatherDefaultFontSz
                }

                // ────── Separator ──────
                Separator {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: highTemp.implicitWidth
                    color: Settings.colors.background.tint4
                    opacity: Settings.colors.background.dimOpacity
                }

                Text {
                    Layout.topMargin: Configuration.weatherCardDateSpacingOffset
                    Layout.alignment: Qt.AlignHCenter
                    text: root.dateText()
                    color: Settings.colors.foreground.main
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.weatherSubFontSz
                }
            }
        }

        Separator {
            Layout.row: 0
            Layout.column: 2
            Layout.rowSpan: 2
            Layout.preferredHeight: cardGrid.implicitHeight
            orientation: Qt.Vertical
            color: Settings.colors.background.tint4
            opacity: Settings.colors.background.dimOpacity
        }

        Item {
            id: precipitationCell

            Layout.row: 0
            Layout.column: 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: precipitationCard.implicitWidth
            implicitHeight: precipitationCard.implicitHeight

            ColumnLayout {
                id: precipitationCard
                anchors.centerIn: parent
                spacing: 0

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Configuration.weatherCardCellTitleHSpacing

                    Glyph {
                        Layout.alignment: Qt.AlignVCenter
                        icon: Configuration.weatherIcon.precipitation
                        iconSize: Configuration.weatherCardIndicatorIconSz
                        useMetrics: false
                        color: Configuration.weatherFontColor.rain_title
                    }

                    Text {
                        text: "RAIN"
                        color: Configuration.weatherFontColor.rain_title
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: Configuration.weatherSubFontSz
                    }
                }

                RowLayout {
                    spacing: Configuration.weatherCardCompositeEntryHSpacing

                    ValueUnit {
                        value: root.day?.precipitationProbability ?? NaN
                        unit: "%"
                        decimals: Configuration.weatherMeasurementDecimals
                        unitSpacingRatio: Configuration.weatherValueUnitSpacingRatio
                        unknownText: root.service.unknownText

                        fontSize: Configuration.weatherSubFontSz
                    }

                    Circle {
                        Layout.alignment: Qt.AlignVCenter
                        diameter: Settings.separatorDotSize
                        color: Settings.colors.foreground.muted
                    }

                    ValueUnit {
                        value: root.day?.precipitationSum ?? NaN
                        unit: root.service.getPrecipitationUnitLabel()
                        decimals: Configuration.weatherPrecipitationDecimals
                        unitSpacingRatio: Configuration.weatherValueUnitSpacingRatio
                        unknownText: root.service.unknownText
                        fontSize: Configuration.weatherSubFontSz
                    }
                }
            }
        }

        Item {
            id: windCell

            Layout.row: 1
            Layout.column: 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: precipitationCard.implicitWidth
            implicitHeight: precipitationCard.implicitHeight

            ColumnLayout {
                id: windCard
                anchors.centerIn: parent
                spacing: 0

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Configuration.weatherCardCellTitleHSpacing

                    Glyph {
                        Layout.alignment: Qt.AlignVCenter
                        icon: Configuration.weatherIcon.wind
                        iconSize: Configuration.weatherCardIndicatorIconSz
                        useMetrics: false
                        color: Configuration.weatherFontColor.wind_title
                    }

                    Text {
                        text: "WIND"
                        color: Configuration.weatherFontColor.wind_title
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: Configuration.weatherSubFontSz
                    }
                }

                RowLayout {
                    spacing: Configuration.weatherCardCellTitleHSpacing
                    Layout.alignment: Qt.AlignHCenter

                    ValueUnit {
                        id: windSpeed

                        value: root.day?.windSpeedMax ?? NaN
                        unit: root.service.getWindSpeedUnitLabel()
                        decimals: Configuration.weatherMeasurementDecimals
                        unitSpacingRatio: Configuration.weatherValueUnitSpacingRatio
                        unknownText: root.service.unknownText
                        fontSize: Configuration.weatherSubFontSz
                    }

                    Circle {
                        Layout.alignment: Qt.AlignVCenter
                        diameter: Settings.separatorDotSize
                        color: Settings.colors.foreground.muted
                    }

                    Item {
                        Layout.leftMargin: -Configuration.weatherCardCellTitleHSpacing

                        visible: root.hasWindDirection
                        implicitWidth: windDirectionGlyph.implicitWidth
                        // The wind speed determines the row's vertical spacing.
                        implicitHeight: windSpeed.implicitHeight

                        Glyph {
                            id: windDirectionGlyph

                            anchors.centerIn: parent
                            icon: Configuration.weatherIcon.windDirection
                            iconSize: Configuration.weatherCardWindDirectionIconSz
                            rotation: root.windArrowRotation()
                            useMetrics: true
                        }
                    }
                }
            }
        }

        Item {
            id: sunriseCell

            Layout.row: 0
            Layout.column: 4
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: sunriseCard.implicitWidth
            implicitHeight: sunriseCard.implicitHeight

            ColumnLayout {
                id: sunriseCard
                anchors.centerIn: parent
                spacing: 0

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Configuration.weatherCardCellTitleHSpacing

                    Glyph {
                    Layout.alignment: Qt.AlignVCenter
                    icon: Configuration.weatherIcon.sunrise
                    iconSize: Configuration.weatherCardIndicatorIconSz
                    useMetrics: false
                    color: Configuration.weatherFontColor.sunrise_title
                }

                    Text {
                        text: "SUNRISE"
                        color: Configuration.weatherFontColor.sunrise_title
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: Configuration.weatherSubFontSz
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.service.formatClockTime(root.day?.sunrise ?? "")
                    color: Settings.colors.foreground.main
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.weatherSubFontSz
                }
            }
        }

        Item {
            id: sunsetCell

            Layout.row: 1
            Layout.column: 4
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: sunsetCard.implicitWidth
            implicitHeight: sunsetCard.implicitHeight

            ColumnLayout {
                id: sunsetCard
                anchors.centerIn: parent
                spacing: 0

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Configuration.weatherCardCellTitleHSpacing

                    Glyph {
                    Layout.alignment: Qt.AlignVCenter
                    icon: Configuration.weatherIcon.sunset
                    iconSize: Configuration.weatherCardIndicatorIconSz
                    useMetrics: false
                    color: Configuration.weatherFontColor.sunset_title
                }

                    Text {
                        text: "SUNSET"
                        color: Configuration.weatherFontColor.sunset_title
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: Configuration.weatherSubFontSz
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.service.formatClockTime(root.day?.sunset ?? "")
                    color: Settings.colors.foreground.main
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.weatherSubFontSz
                }
            }
        }
    }

    // ────── Helper Functions ──────
    function dateText(): string {
        if (!root.day?.date)
            return root.service.unknownText

        const parts = root.day.date.split("-")
        return parts[2] + "/" + parts[1]
    }

    function windArrowRotation(): real {
        if (!root.hasWindDirection)
            return 0

        return root.day.windDirectionDominant + Configuration.weatherWindArrowNorthRotation
    }

    function windDirectionText(): string {
        return "Wind from " + root.service.formatBearing(root.day?.windDirectionDominant ?? NaN)
    }
}
