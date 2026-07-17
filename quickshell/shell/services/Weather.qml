pragma Singleton

import QtQuick
import Quickshell
import "../utils"

// Current weather (Open-Meteo), geolocated via ipinfo.io. No location
// config exists yet (services/Config.qml has no weather-location slot), so
// this always just guesses from the box's public IP on startup — manual
// city config / forward geocoding / Nominatim reverse-geocode fallback /
// diacritics table are all skipped until a config surface exists to drive
// them (see references/caelestia-dashboard-reference.md's Weather section
// for the full port plan).
//
// No ref-counted activation: unlike SystemUsage/NetworkUsage's continuous
// /proc polling, this is one geolocation call at startup plus a refetch
// once an hour — cheap enough that gating it behind a card being on
// screen isn't worth the complexity, and keeping it always-on means the
// data is already fresh whenever the dashboard is opened rather than
// waiting on a fetch.
Singleton {
    id: root

    property real latitude: NaN
    property real longitude: NaN
    property bool loading: true
    property bool hasError: false

    readonly property real currentTemp: _currentTemp
    readonly property int weatherCode: _weatherCode
    readonly property real todayHigh: _todayHigh
    readonly property real todayLow: _todayLow

    property real _currentTemp: NaN
    property int _weatherCode: -1
    property real _todayHigh: NaN
    property real _todayLow: NaN

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
            root.fetchForecast();
        }, () => {
            root.hasError = true;
            root.loading = false;
        });
    }

    function fetchForecast(): void {
        if (isNaN(root.latitude) || isNaN(root.longitude))
            return;

        const url = "https://api.open-meteo.com/v1/forecast" + "?latitude=" + root.latitude + "&longitude=" + root.longitude + "&current=temperature_2m,weather_code" + "&daily=temperature_2m_max,temperature_2m_min" + "&timezone=auto&forecast_days=1";

        Requests.get(url, data => {
            if (!data.current || !data.daily) {
                root.hasError = true;
                root.loading = false;
                return;
            }

            root._currentTemp = data.current.temperature_2m;
            root._weatherCode = data.current.weather_code;
            root._todayHigh = data.daily.temperature_2m_max[0];
            root._todayLow = data.daily.temperature_2m_min[0];
            root.hasError = false;
            root.loading = false;
        }, () => {
            root.hasError = true;
            root.loading = false;
        });
    }

    Component.onCompleted: root.geolocate()

    // Refetch hourly (no location-change trigger yet — there's no config to change)
    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.fetchForecast()
    }
}
