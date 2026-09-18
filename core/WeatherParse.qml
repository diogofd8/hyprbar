pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs

//
// Weather back end.
//
// Polls Open-Meteo (free, no API key) once per WeatherConfig.refreshIntervalMinutes,
// normalises the response into a flat snapshot, and mirrors that snapshot to disk so
// the bar still has something to draw after a suspend, a reboot, or a config hot
// reload -- the network is only touched again once the cached snapshot goes stale.
//
// Consumers should bind to the ready-to-render properties near the top (icon,
// temperatureText, ...) and reach into `current` / `daily` / `location` for anything
// a future dropdown needs.
//
Singleton {
    id: root

    // ══════════════════════════════════════════════════════════════════════
    //  Status
    // ══════════════════════════════════════════════════════════════════════

    readonly property bool hasData: internal.snapshot !== null
    readonly property bool loading: internal.inFlight !== 0

    // Empty while things are healthy, otherwise a short human-readable reason.
    readonly property string lastError: internal.lastError

    // Date of the last successful fetch, or null if we have never had one.
    readonly property var lastUpdated:
        internal.snapshot ? new Date(internal.snapshot.fetchedAt) : null

    // Rendered in place of any value we do not have.
    readonly property string unknownText: "--"

    // ══════════════════════════════════════════════════════════════════════
    //  Current conditions, ready to render
    // ══════════════════════════════════════════════════════════════════════

    readonly property string icon: iconForCode(current.weatherCode, current.isDay)
    readonly property string description: descriptionForCode(current.weatherCode)

    // Bare numbers -- Temperature.qml draws the degree sign and the unit letter itself.
    readonly property string temperatureText: formatTemperature(current.temperature)
    readonly property string apparentTemperatureText: formatTemperature(current.apparentTemperature)

    // Number + unit -- nothing else renders the unit for these.
    readonly property string humidityText: formatPercent(current.humidity)
    readonly property string precipitationText: formatPrecipitation(current.precipitation)
    readonly property string pressureText: formatPressure(current.pressure)
    readonly property string windText: formatWindSpeed(current.windSpeed)
    readonly property string windBearingText: formatBearing(current.windDirection)
    readonly property string visibilityText: formatVisibility(current.visibility)

    readonly property string sunriseText: formatClockTime(daily.length > 0 ? daily[0].sunrise : "")
    readonly property string sunsetText: formatClockTime(daily.length > 0 ? daily[0].sunset : "")

    // ══════════════════════════════════════════════════════════════════════
    //  Structured data
    // ══════════════════════════════════════════════════════════════════════

    // { label, latitude, longitude, timezone }
    readonly property var location: internal.snapshot ? internal.snapshot.location : blankLocation

    // Every numeric field is NaN when unknown, so guard with formatters or Number.isFinite.
    //
    //   time                 string, ISO local time of the reading
    //   isDay                bool
    //   weatherCode          int, WMO code (-1 when unknown)
    //   temperature          in WeatherConfig.temperatureUnit
    //   apparentTemperature  in WeatherConfig.temperatureUnit
    //   humidity             %
    //   precipitation        mm
    //   pressure             in WeatherConfig.pressureUnit (converted on read)
    //   windSpeed            in WeatherConfig.windSpeedUnit
    //   windDirection        degrees clockwise from north
    //   visibility           metres
    readonly property var current: {
        if (!internal.snapshot)
            return blankCurrent;

        // Pressure is cached in hPa so switching PressureUnit needs no refetch.
        return Object.assign({}, internal.snapshot.current, {
            pressure: toConfiguredPressure(internal.snapshot.current.pressure)
        });
    }

    // One entry per forecast day, [0] being today:
    //
    //   date                      string, "YYYY-MM-DD"
    //   weatherCode               int, WMO code
    //   icon, description         resolved from weatherCode (always the daytime glyph)
    //   temperatureMax/Min        in WeatherConfig.temperatureUnit
    //   sunrise, sunset           string, ISO local time
    //   precipitationSum          mm
    //   precipitationProbability  %
    //   windSpeedMax              in WeatherConfig.windSpeedUnit
    readonly property var daily: {
        if (!internal.snapshot)
            return [];

        return internal.snapshot.daily.map(day => Object.assign({}, day, {
            icon: iconForCode(day.weatherCode, true),
            description: descriptionForCode(day.weatherCode)
        }));
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Unit labels
    // ══════════════════════════════════════════════════════════════════════

    function getTemperatureUnitLetter(): string {
        return WeatherConfig.temperatureUnit === WeatherConfig.TemperatureUnit.Fahrenheit ? "F" : "C";
    }

    function getWindSpeedUnitLabel(): string {
        switch (WeatherConfig.windSpeedUnit) {
        case WeatherConfig.WindSpeedUnit.MilesPerHour:    return "mph";
        case WeatherConfig.WindSpeedUnit.MetersPerSecond: return "m/s";
        default:                                          return "km/h";
        }
    }

    function getPressureUnitLabel(): string {
        return WeatherConfig.pressureUnit === WeatherConfig.PressureUnit.InchesOfMercury ? "inHg" : "hPa";
    }

    function getPrecipitationUnitLabel(): string {
        return "mm";
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Formatters -- every one of them renders unknownText for missing values
    // ══════════════════════════════════════════════════════════════════════

    function formatTemperature(value: real): string {
        return isNumber(value) ? String(Math.round(value)) : unknownText;
    }

    function formatPercent(value: real): string {
        return isNumber(value) ? Math.round(value) + "%" : unknownText;
    }

    function formatPrecipitation(value: real): string {
        return isNumber(value) ? value.toFixed(1) + " " + getPrecipitationUnitLabel() : unknownText;
    }

    function formatPressure(value: real): string {
        if (!isNumber(value))
            return unknownText;

        const rounded = WeatherConfig.pressureUnit === WeatherConfig.PressureUnit.InchesOfMercury
            ? value.toFixed(2)
            : String(Math.round(value));

        return rounded + " " + getPressureUnitLabel();
    }

    function formatWindSpeed(value: real): string {
        return isNumber(value) ? Math.round(value) + " " + getWindSpeedUnitLabel() : unknownText;
    }

    // Degrees clockwise from north to a 16-point compass label.
    function formatBearing(degrees: real): string {
        if (!isNumber(degrees))
            return unknownText;

        return compassPoints[Math.round(degrees / 22.5) % 16];
    }

    function formatVisibility(metres: real): string {
        if (!isNumber(metres))
            return unknownText;

        return metres < 1000 ? Math.round(metres) + " m" : (metres / 1000).toFixed(1) + " km";
    }

    // "2026-09-12T07:11" -> "07:11". Sliced rather than parsed: Open-Meteo already
    // returns times local to the forecast location, and re-parsing would drag them
    // into this machine's timezone.
    function formatClockTime(isoTime: string): string {
        const time = String(isoTime).slice(11, 16);
        return time.length === 5 ? time : unknownText;
    }

    // "2026-09-12" -> "FRI"
    function formatDayLabel(isoDate: string): string {
        const parts = String(isoDate).split("-");
        if (parts.length !== 3)
            return unknownText;

        const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
        return isNaN(date.getTime()) ? unknownText : Qt.formatDate(date, "ddd").toUpperCase();
    }

    // ══════════════════════════════════════════════════════════════════════
    //  WMO weather code lookup
    // ══════════════════════════════════════════════════════════════════════

    function iconForCode(code: int, isDay: bool): string {
        const entry = weatherCodes[code];
        if (!entry)
            return unknownIcon;

        return isDay ? entry.day : entry.night;
    }

    function descriptionForCode(code: int): string {
        const entry = weatherCodes[code];
        return entry ? entry.text : "Unavailable";
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Control
    // ══════════════════════════════════════════════════════════════════════

    // Fetch now, ignoring the refresh interval and the retry backoff.
    function refresh() {
        internal.lastAttemptAt = 0;
        internal.fetch();
    }

    // Drop the cached snapshot and start over.
    function reset() {
        internal.snapshot = null;
        internal.geocode = null;
        internal.lastError = "";
        refresh();
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Internals
    // ══════════════════════════════════════════════════════════════════════

    readonly property string unknownIcon: "󰼯" // nf-md-weather_cloudy_alert

    readonly property var weatherCodes: ({
        0:   { day: "󰖙", night: "󰖔", text: "Clear sky" },                         // nf-md-weather_sunny / nf-md-weather_night
        1:   { day: "󰖙", night: "󰖔", text: "Mainly clear" },                      // nf-md-weather_sunny / nf-md-weather_night
        2:   { day: "󰖕", night: "󰼱", text: "Partly cloudy" },                     // nf-md-weather_partly_cloudy / nf-md-weather_night_partly_cloudy
        3:   { day: "󰖐", night: "󰖐", text: "Overcast" },                          // nf-md-weather_cloudy
        45:  { day: "󰖑", night: "󰖑", text: "Fog" },                               // nf-md-weather_fog
        48:  { day: "󰼰", night: "󰼰", text: "Depositing rime fog" },               // nf-md-weather_hazy
        51:  { day: "󰖗", night: "󰖗", text: "Light drizzle" },                     // nf-md-weather_rainy
        53:  { day: "󰖗", night: "󰖗", text: "Moderate drizzle" },                  // nf-md-weather_rainy
        55:  { day: "󰖖", night: "󰖖", text: "Dense drizzle" },                     // nf-md-weather_pouring
        56:  { day: "󰼳", night: "󰼳", text: "Light freezing drizzle" },            // nf-md-weather_snowy_rainy
        57:  { day: "󰼳", night: "󰼳", text: "Dense freezing drizzle" },            // nf-md-weather_snowy_rainy
        61:  { day: "󰖗", night: "󰖗", text: "Slight rain" },                       // nf-md-weather_rainy
        63:  { day: "󰖗", night: "󰖗", text: "Moderate rain" },                     // nf-md-weather_rainy
        65:  { day: "󰖖", night: "󰖖", text: "Heavy rain" },                        // nf-md-weather_pouring
        66:  { day: "󰼳", night: "󰼳", text: "Light freezing rain" },               // nf-md-weather_snowy_rainy
        67:  { day: "󰼳", night: "󰼳", text: "Heavy freezing rain" },               // nf-md-weather_snowy_rainy
        71:  { day: "󰖘", night: "󰖘", text: "Slight snowfall" },                   // nf-md-weather_snowy
        73:  { day: "󰖘", night: "󰖘", text: "Moderate snowfall" },                 // nf-md-weather_snowy
        75:  { day: "󰼶", night: "󰼶", text: "Heavy snowfall" },                    // nf-md-weather_snowy_heavy
        77:  { day: "󰖘", night: "󰖘", text: "Snow grains" },                       // nf-md-weather_snowy
        80:  { day: "󰖗", night: "󰖗", text: "Slight rain showers" },               // nf-md-weather_rainy
        81:  { day: "󰖗", night: "󰖗", text: "Moderate rain showers" },             // nf-md-weather_rainy
        82:  { day: "󰖖", night: "󰖖", text: "Violent rain showers" },              // nf-md-weather_pouring
        85:  { day: "󰖘", night: "󰖘", text: "Slight snow showers" },               // nf-md-weather_snowy
        86:  { day: "󰼶", night: "󰼶", text: "Heavy snow showers" },                // nf-md-weather_snowy_heavy
        95:  { day: "󰖓", night: "󰖓", text: "Thunderstorm" },                      // nf-md-weather_lightning
        96:  { day: "󰖒", night: "󰖒", text: "Thunderstorm with slight hail" },     // nf-md-weather_hail
        99:  { day: "󰖒", night: "󰖒", text: "Thunderstorm with heavy hail" },      // nf-md-weather_hail
    })

    readonly property var compassPoints: [
        "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
        "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"
    ]

    readonly property var blankLocation: ({
        label: "",
        latitude: NaN,
        longitude: NaN,
        timezone: ""
    })

    readonly property var blankCurrent: ({
        time: "",
        isDay: true,
        weatherCode: -1,
        temperature: NaN,
        apparentTemperature: NaN,
        humidity: NaN,
        precipitation: NaN,
        pressure: NaN,
        windSpeed: NaN,
        windDirection: NaN,
        visibility: NaN
    })

    function isNumber(value): bool {
        return typeof value === "number" && isFinite(value);
    }

    function toConfiguredPressure(hectopascal: real): real {
        if (!isNumber(hectopascal))
            return NaN;

        return WeatherConfig.pressureUnit === WeatherConfig.PressureUnit.InchesOfMercury
            ? hectopascal * 0.0295299830714
            : hectopascal;
    }

    QtObject {
        id: internal

        // ────── Endpoints ──────
        readonly property string forecastEndpoint: "https://api.open-meteo.com/v1/forecast"
        readonly property string geocodeEndpoint: "https://geocoding-api.open-meteo.com/v1/search"

        readonly property var currentFields: [
            "temperature_2m", "apparent_temperature", "relative_humidity_2m",
            "precipitation", "weather_code", "surface_pressure",
            "wind_speed_10m", "wind_direction_10m", "visibility", "is_day"
        ]

        readonly property var dailyFields: [
            "weather_code", "temperature_2m_max", "temperature_2m_min",
            "sunrise", "sunset", "precipitation_sum",
            "precipitation_probability_max", "wind_speed_10m_max"
        ]

        // ────── Cache ──────

        // Bumped whenever the shape of a snapshot changes, so an old cache
        // file is discarded instead of being read as the new layout.
        readonly property int schemaVersion: 1

        // The request parameters baked into the cached snapshot. A change here
        // invalidates the cache; PressureUnit is deliberately absent because
        // pressure is stored in hPa and converted on read.
        readonly property string requestKey: [
            WeatherConfig.locationMode,
            WeatherConfig.locationMode === WeatherConfig.LocationMode.Name
                ? WeatherConfig.locationName
                : WeatherConfig.latitude + "," + WeatherConfig.longitude,
            WeatherConfig.temperatureUnit,
            WeatherConfig.windSpeedUnit,
            forecastDays
        ].join("|")

        onRequestKeyChanged: {
            if (!started)
                return;

            snapshot = null;
            geocode = null;
            root.refresh();
        }

        // ────── Timing ──────
        readonly property int forecastDays: Math.max(1, Math.min(16, WeatherConfig.forecastDays))
        readonly property int refreshMs: Math.max(1, WeatherConfig.refreshIntervalMinutes) * 60000
        readonly property int retryMs: 60000
        readonly property int requestTimeoutMs: 30000

        // ────── Mutable state ──────
        property var snapshot: null
        property var geocode: null
        property string lastError: ""
        property bool started: false

        // Generation id of the request in flight, 0 when idle. Every request
        // captures the id it was issued under and drops its response if a newer
        // request has been issued since -- otherwise a slow reply from a stale
        // config could overwrite a fresh one.
        property int inFlight: 0
        property int generation: 0
        property real inFlightSince: 0
        property real lastAttemptAt: 0

        // ────── Polling ──────

        // Deliberately a staleness check on a short tick rather than a single
        // refreshMs timer: a QML Timer does not make up for time lost while the
        // machine is suspended, so on resume this notices the snapshot has aged
        // out and refetches, instead of waiting out the rest of the interval.
        function tick() {
            const now = Date.now();

            if (inFlight !== 0) {
                if (now - inFlightSince < requestTimeoutMs)
                    return;

                // Abandon it; the generation guard makes the late reply a no-op.
                inFlight = 0;
                lastError = "Request timed out";
            }

            if (snapshot && now - snapshot.fetchedAt < refreshMs)
                return;

            if (now - lastAttemptAt < retryMs)
                return;

            fetch();
        }

        function fetch() {
            if (inFlight !== 0 && Date.now() - inFlightSince < requestTimeoutMs)
                return;

            lastAttemptAt = Date.now();
            inFlightSince = lastAttemptAt;
            inFlight = ++generation;

            resolveLocation(inFlight, place => requestForecast(inFlight, place));
        }

        // ────── Location ──────

        function resolveLocation(token: int, onResolved) {
            if (WeatherConfig.locationMode === WeatherConfig.LocationMode.Coordinates) {
                onResolved({
                    latitude: WeatherConfig.latitude,
                    longitude: WeatherConfig.longitude,
                    label: formatCoordinates(WeatherConfig.latitude, WeatherConfig.longitude)
                });
                return;
            }

            if (geocode && geocode.query === WeatherConfig.locationName) {
                onResolved(geocode);
                return;
            }

            const wanted = parseLocationName(WeatherConfig.locationName);
            if (wanted.name === "") {
                fail(token, "No location name configured");
                return;
            }

            const url = geocodeEndpoint
                + "?name=" + encodeURIComponent(wanted.name)
                + "&count=10&language=en&format=json";

            request(token, url, data => {
                const results = data.results || [];
                const match = results.find(result =>
                    wanted.country === "" || String(result.country_code).toUpperCase() === wanted.country);

                if (!match) {
                    fail(token, "Unknown location: " + WeatherConfig.locationName);
                    return;
                }

                geocode = {
                    query: WeatherConfig.locationName,
                    latitude: match.latitude,
                    longitude: match.longitude,
                    label: match.country_code ? match.name + ", " + match.country_code : match.name
                };

                onResolved(geocode);
            });
        }

        // "Porto,PT" / "Porto, PT" / "Porto" -> { name, country }
        function parseLocationName(raw: string): var {
            const parts = String(raw).split(",");
            return {
                name: parts[0].trim(),
                country: parts.length > 1 ? parts[1].trim().toUpperCase() : ""
            };
        }

        function formatCoordinates(latitude: real, longitude: real): string {
            return latitude.toFixed(2) + ", " + longitude.toFixed(2);
        }

        // ────── Forecast ──────

        function requestForecast(token: int, place) {
            const url = forecastEndpoint
                + "?latitude=" + place.latitude
                + "&longitude=" + place.longitude
                + "&current=" + currentFields.join(",")
                + "&daily=" + dailyFields.join(",")
                + "&timezone=auto"
                + "&forecast_days=" + forecastDays
                + "&temperature_unit=" + apiTemperatureUnit()
                + "&wind_speed_unit=" + apiWindSpeedUnit()
                + "&precipitation_unit=mm";

            request(token, url, data => {
                snapshot = ingest(data, place.label);
                lastError = "";
                inFlight = 0;
                cache.setText(JSON.stringify(snapshot));
            });
        }

        function apiTemperatureUnit(): string {
            return WeatherConfig.temperatureUnit === WeatherConfig.TemperatureUnit.Fahrenheit
                ? "fahrenheit" : "celsius";
        }

        function apiWindSpeedUnit(): string {
            switch (WeatherConfig.windSpeedUnit) {
            case WeatherConfig.WindSpeedUnit.MilesPerHour:    return "mph";
            case WeatherConfig.WindSpeedUnit.MetersPerSecond: return "ms";
            default:                                          return "kmh";
            }
        }

        // Open-Meteo response -> the snapshot shape documented on `current` / `daily`.
        function ingest(data, label: string): var {
            const now = data.current || {};
            const forecast = data.daily || {};
            const dates = forecast.time || [];
            const days = [];

            for (let i = 0; i < dates.length; i++) {
                days.push({
                    date: dates[i],
                    weatherCode: pickInt(forecast.weather_code, i),
                    temperatureMax: pick(forecast.temperature_2m_max, i),
                    temperatureMin: pick(forecast.temperature_2m_min, i),
                    sunrise: pickString(forecast.sunrise, i),
                    sunset: pickString(forecast.sunset, i),
                    precipitationSum: pick(forecast.precipitation_sum, i),
                    precipitationProbability: pick(forecast.precipitation_probability_max, i),
                    windSpeedMax: pick(forecast.wind_speed_10m_max, i)
                });
            }

            return {
                version: schemaVersion,
                requestKey: requestKey,
                fetchedAt: Date.now(),
                location: {
                    label: label,
                    latitude: number(data.latitude),
                    longitude: number(data.longitude),
                    timezone: String(data.timezone || "")
                },
                current: {
                    time: String(now.time || ""),
                    isDay: now.is_day === undefined ? true : now.is_day === 1,
                    weatherCode: now.weather_code === undefined ? -1 : now.weather_code,
                    temperature: number(now.temperature_2m),
                    apparentTemperature: number(now.apparent_temperature),
                    humidity: number(now.relative_humidity_2m),
                    precipitation: number(now.precipitation),
                    pressure: number(now.surface_pressure), // always hPa, converted on read
                    windSpeed: number(now.wind_speed_10m),
                    windDirection: number(now.wind_direction_10m),
                    visibility: number(now.visibility)
                },
                daily: days
            };
        }

        function number(value): real {
            return root.isNumber(value) ? value : NaN;
        }

        function pick(list, index: int): real {
            return Array.isArray(list) ? number(list[index]) : NaN;
        }

        function pickInt(list, index: int): int {
            const value = pick(list, index);
            return root.isNumber(value) ? value : -1;
        }

        function pickString(list, index: int): string {
            return Array.isArray(list) && list[index] !== undefined ? String(list[index]) : "";
        }

        // ────── HTTP ──────

        // QML's XMLHttpRequest has no timeout of its own; tick() watches the clock
        // and the generation guard here makes any late reply harmless.
        function request(token: int, url: string, onSuccess) {
            const xhr = new XMLHttpRequest();

            xhr.onreadystatechange = () => {
                if (xhr.readyState !== XMLHttpRequest.DONE || token !== generation)
                    return;

                if (xhr.status !== 200) {
                    fail(token, xhr.status === 0 ? "Network unreachable" : "HTTP " + xhr.status);
                    return;
                }

                try {
                    onSuccess(JSON.parse(xhr.responseText));
                } catch (error) {
                    fail(token, "Malformed response");
                    console.warn("WeatherParse: " + error);
                }
            };

            xhr.open("GET", url);
            xhr.send();
        }

        function fail(token: int, reason: string) {
            if (token !== generation)
                return;

            inFlight = 0;
            lastError = reason;
            console.warn("WeatherParse: " + reason);
        }

        // ────── Disk cache ──────

        function restore() {
            const text = cache.text();
            if (text === "")
                return;

            try {
                const stored = JSON.parse(text);

                // Anything written by an older schema, or fetched for a different
                // location or set of units, is not ours to display.
                if (stored.version !== schemaVersion || stored.requestKey !== requestKey)
                    return;

                snapshot = stored;
            } catch (error) {
                console.warn("WeatherParse: discarding unreadable cache (" + error + ")");
            }
        }
    }

    // Read once, synchronously, so the bar draws the last known weather on the very
    // first frame rather than flashing placeholders until the network answers.
    FileView {
        id: cache

        path: Quickshell.cachePath("weather.json")
        blockLoading: true
        atomicWrites: true
        printErrors: false // a missing cache on first run is not an error
    }

    Timer {
        interval: 20000
        running: true
        repeat: true
        onTriggered: internal.tick()
    }

    Component.onCompleted: {
        internal.restore();
        internal.started = true;
        internal.tick();
    }
}
