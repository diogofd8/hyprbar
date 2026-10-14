pragma Singleton

import QtQuick
import Quickshell

import qs

Singleton {
    // ────── Center Piece Sizing ──────
    readonly property real widgetWidth: 386
    readonly property real widgetHeight: 273
    readonly property real pagePadding: 8
    readonly property real tabButtonSpacing: 12
    readonly property real tabIconPaddingX: 8
    readonly property real tabSelectorWidth: 2
    readonly property real tabSelectorSpacing: 1

    readonly property real mainTextFontSz: 18
    readonly property real subTextFontSz: 11

    // ────── Center Piece Icons ──────
    readonly property var tabIcon: ({
        calendar: "",
        weather: ""
    })

    //  

    readonly property var tabs: [
        {key: "calendar", label: "Calendar"},
        {key: "weather", label: "Weather"}
    ]

    // ────── Calendar Page ──────
    readonly property real calendarPaddingX: 4
    readonly property real calendarPaddingY: 6
    readonly property real calendarCellPadding: 4
    readonly property real calendarCellSpacing: 8
    readonly property int calendarMinimumRows: 6
    readonly property real calendarNavBtnSpacing: 12
    readonly property real calendarNavBtnPadding: 4
    readonly property real calendarFontSz: 13

    readonly property var calendarNavigationIcon: ({
        previousMonth: "",
        currentMonth: "󰁯",
        nextMonth: ""
    })

    // ────── Weather Page ──────
    readonly property real weatherColumnVSpacing: 8
    readonly property real weatherTitleRowHSpacing: 8
    readonly property real weatherLocationFieldHSpacing: 6
    readonly property real weatherLocationDotSize: 8

    readonly property real weatherDefaultFontSz: 14
    readonly property real weatherSubFontSz: 12
    readonly property real weatherValueUnitSpacingRatio: 0.05
    readonly property int weatherPrecipitationDecimals: 1
    readonly property int weatherMeasurementDecimals: 0

    // ────── Weather Card ──────
    readonly property real weatherCardPaddingX: 0
    readonly property real weatherCardPaddingY: 2

    readonly property real weatherCardCompositeEntryHSpacing: 3
    readonly property real weatherCardTempRangeSpacerWidthOffset: 4
    readonly property real weatherCardTempRangeSpacingOffset: 2
    readonly property real weatherCardCellTitleHSpacing: 4
    readonly property real weatherCardDescriptionPaddingX: 8
    readonly property real weatherCardDateSpacing: 1
    readonly property real weatherCardDateSpacingOffset: 2

    readonly property real weatherConditionIconSize: 32
    readonly property real weatherCardIndicatorIconSz: 14
    readonly property real weatherCardWindDirectionIconSz: 20
    readonly property real weatherCardTempMaxFontSz: 16
    readonly property real weatherCardTempMinFontSz: 12
    readonly property real weatherCardDescriptionReducedFontSz: 12

    // ────── Weather Entry ──────
    readonly property real weatherEntriesHSpacing: 4
    readonly property real weatherEntryPadding: 2
    readonly property real weatherEntryVSpacing: 4
    readonly property real weatherEntryHSpacing: 2

    readonly property real weatherEntryTempRangeSpacingOffset: 2
    readonly property real weatherEntrySeparatorWidth: 24

    readonly property real weatherEntryIconSize: 20
    readonly property real weatherEntryIndicatorIconSz: 12
    readonly property real weatherEntryFontSz: 12
    readonly property real weatherEntryTempMaxSz: 16
    readonly property real weatherEntryTempMinSz: 14

    // The arrow glyph points east at zero rotation; bearings start at north.
    readonly property real weatherWindArrowNorthRotation: -90
    readonly property real weatherRefreshStartRotation: 360

    readonly property var weatherIcon: ({
        refresh: "󰓦",
        precipitation: "󰖌",
        wind: "󰖝",
        windDirection: "",
        sunrise: "",
        sunset: ""
    })

    readonly property var weatherFontColor: ({
        rain_title: "#477AB0",
        wind_title: "#7B8279",
        sunrise_title: "#AB791C",
        sunset_title: "#7486BC",
        temp_high: "#DAA250",
        temp_low: "#5088DA",
    })

    readonly property var weatherGlyphColorDay: ({
        clear: "#AB791C",
        partly_cloudy: "#8B7954",
        overcast: "#737D8B",
        foggy: "#7B8279",
        rainy: "#477AB0",
        snowy: "#4F92A7",
        thunder: "#8D65AD",
    })

    readonly property var weatherGlyphColorNight: ({
        clear: "#7486BC",
        partly_cloudy: "#8583A6",
        overcast: "#767C96",
        foggy: "#778C91",
        rainy: "#527AAB",
        snowy: "#6296AE",
        thunder: "#9466AD",
    })

    readonly property var weatherGlyphCategory: ({
        "󰖙": "clear",
        "󰖔": "clear",
        "󰖕": "partly_cloudy",
        "󰼱": "partly_cloudy",
        "󰖐": "overcast",
        "󰖑": "foggy",
        "󰼰": "foggy",
        "󰖗": "rainy",
        "󰖖": "rainy",
        "󰼳": "rainy",
        "󰖘": "snowy",
        "󰼶": "snowy",
        "󰖓": "thunder",
        "󰖒": "thunder"
    })

    function weatherGlyphColor(icon: string, isDay: bool): color {
        const palette = isDay ? weatherGlyphColorDay : weatherGlyphColorNight
        return palette[weatherGlyphCategory[icon]] ?? Settings.colors.fgMain
    }
}
