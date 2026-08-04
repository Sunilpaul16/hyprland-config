pragma Singleton

import QtQuick
import Quickshell
import "../utils"

// Weather service
Singleton {
    id: root

    property real latitude: NaN
    property real longitude: NaN
    property string city: ""
    // "celsius" | "fahrenheit"
    readonly property string units: Config.weather.units
    // Unit symbol
    readonly property string unitSymbol: root.units === "fahrenheit" ? "°F" : "°C"

    // Unit is baked into the URL
    onUnitsChanged: root.fetchForecast()
    property bool loading: true
    property bool hasError: false
    // First load flag
    property bool hasLoadedOnce: false

    readonly property real currentTemp: _currentTemp
    readonly property int weatherCode: _weatherCode
    readonly property real todayHigh: _todayHigh
    readonly property real todayLow: _todayLow
    readonly property int humidity: _humidity
    readonly property real feelsLike: _feelsLike
    readonly property real windSpeed: _windSpeed
    readonly property list<var> forecast: _forecast

    // Formatted sun times
    readonly property string sunrise: _sunriseIso.length > 0 ? Qt.formatDateTime(new Date(_sunriseIso), Time.use12Hour ? "h:mm AP" : "hh:mm") : "--:--"
    readonly property string sunset: _sunsetIso.length > 0 ? Qt.formatDateTime(new Date(_sunsetIso), Time.use12Hour ? "h:mm AP" : "hh:mm") : "--:--"

    property real _currentTemp: NaN
    property int _weatherCode: -1
    property real _todayHigh: NaN
    property real _todayLow: NaN
    property int _humidity: -1
    property real _feelsLike: NaN
    property real _windSpeed: NaN
    property string _sunriseIso: ""
    property string _sunsetIso: ""
    property list<var> _forecast: []

    // WMO code icons
    function iconFor(code: int): string {
        if (code === 0)
            return "sunny";
        if (code === 1 || code === 2)
            return "partly_cloudy_day";
        if (code === 3)
            return "cloud";
        if (code === 45 || code === 48)
            return "foggy";
        if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].includes(code))
            return "rainy";
        if ([71, 73, 75, 77, 85, 86].includes(code))
            return "weather_snowy";
        if ([95, 96, 99].includes(code))
            return "thunderstorm";
        return "help";
    }

    function descriptionFor(code: int): string {
        const descriptions = {
            0: "Clear sky",
            1: "Mainly clear",
            2: "Partly cloudy",
            3: "Overcast",
            45: "Fog",
            48: "Fog",
            51: "Light drizzle",
            53: "Drizzle",
            55: "Dense drizzle",
            56: "Freezing drizzle",
            57: "Freezing drizzle",
            61: "Light rain",
            63: "Rain",
            65: "Heavy rain",
            66: "Freezing rain",
            67: "Freezing rain",
            71: "Light snow",
            73: "Snow",
            75: "Heavy snow",
            77: "Snow grains",
            80: "Rain showers",
            81: "Rain showers",
            82: "Violent rain showers",
            85: "Snow showers",
            86: "Snow showers",
            95: "Thunderstorm",
            96: "Thunderstorm with hail",
            99: "Thunderstorm with hail"
        };
        return descriptions[code] ?? "Unknown";
    }

    function geolocate(): void {
        root.loading = true;
        Requests.get("https://ipinfo.io/json", data => {
            const loc = data.loc; // "lat,lon"
            if (!loc) {
                root.hasError = true;
                root.loading = false;
                return;
            }

            const parts = loc.split(",");
            root.latitude = parseFloat(parts[0]);
            root.longitude = parseFloat(parts[1]);
            root.city = data.city ?? "";
            root.fetchForecast();
        }, () => {
            root.hasError = true;
            root.loading = false;
        });
    }

    function fetchForecast(): void {
        if (isNaN(root.latitude) || isNaN(root.longitude))
            return;

        const url = "https://api.open-meteo.com/v1/forecast" + "?latitude=" + root.latitude + "&longitude=" + root.longitude + "&current=temperature_2m,weather_code,relative_humidity_2m,apparent_temperature,wind_speed_10m" + "&daily=temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset" + "&timezone=auto&forecast_days=7" + (root.units === "fahrenheit" ? "&temperature_unit=fahrenheit" : "");

        Requests.get(url, data => {
            // Independent blocks
            let gotAny = false;

            if (data.current) {
                root._currentTemp = data.current.temperature_2m;
                root._weatherCode = data.current.weather_code;
                root._humidity = data.current.relative_humidity_2m;
                root._feelsLike = data.current.apparent_temperature;
                root._windSpeed = data.current.wind_speed_10m;
                gotAny = true;
            }

            if (data.daily) {
                root._todayHigh = data.daily.temperature_2m_max[0];
                root._todayLow = data.daily.temperature_2m_min[0];
                root._sunriseIso = data.daily.sunrise[0] ?? "";
                root._sunsetIso = data.daily.sunset[0] ?? "";
                // Local midnight parse
                root._forecast = (data.daily.time ?? []).map((date, i) => ({
                    date: date.replace(/-/g, "/"),
                    weatherCode: data.daily.weather_code[i],
                    minTemp: data.daily.temperature_2m_min[i],
                    maxTemp: data.daily.temperature_2m_max[i]
                }));
                gotAny = true;
            }

            if (gotAny)
                root.hasLoadedOnce = true;
            root.hasError = !gotAny && !root.hasLoadedOnce;
            root.loading = false;
        }, () => {
            // Keep cached data
            root.hasError = !root.hasLoadedOnce;
            root.loading = false;
        });
    }

    Component.onCompleted: root.geolocate()

    // Hourly refetch
    Timer {
        interval: Math.max(5, Config.weather.refreshMinutes) * 60000
        running: true
        repeat: true
        onTriggered: {
            if (isNaN(root.latitude) || isNaN(root.longitude))
                root.geolocate();
            else
                root.fetchForecast();
        }
    }
}
