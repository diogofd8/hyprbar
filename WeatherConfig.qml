pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // ────── Location ──────
    enum LocationMode {
        Coordinates,
        Name
    }

    readonly property int locationMode:
        WeatherConfig.LocationMode.Name

    readonly property real latitude: 41.1579
    readonly property real longitude: -8.6291
    readonly property string locationName: "Porto,PT"

    // ────── Units ──────
    enum TemperatureUnit {
        Celsius,
        Fahrenheit
    }

    enum WindSpeedUnit {
        KilometersPerHour,
        MilesPerHour,
        MetersPerSecond
    }

    enum PressureUnit {
        Hectopascal,
        InchesOfMercury
    }

    readonly property int temperatureUnit:
        WeatherConfig.TemperatureUnit.Celsius

    readonly property int windSpeedUnit:
        WeatherConfig.WindSpeedUnit.KilometersPerHour

    readonly property int pressureUnit:
        WeatherConfig.PressureUnit.Hectopascal

    // ────── Refresh ──────
    readonly property int refreshIntervalMinutes: 30

    // ────── Forecast ──────
    readonly property int forecastDays: 7

    // ────── Show/Hide Additional Information ──────
    readonly property bool showFeelsLike: true
    readonly property bool showHumidity: true
    readonly property bool showWind: true
    readonly property bool showPrecipitation: true
    readonly property bool showPressure: false
    readonly property bool showVisibility: false
    readonly property bool showSunriseSunset: true
}