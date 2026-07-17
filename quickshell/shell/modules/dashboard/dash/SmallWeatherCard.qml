import QtQuick
import QtQuick.Layouts
import "../../../services"

// Icon + temp + one-line description, sized to content — the compact
// dashboard-tab weather summary (see references/caelestia-dashboard-
// reference.md's "dash/SmallWeather.qml" section). The full WeatherTab.qml
// (7-day forecast, sunrise/sunset, city config) is a follow-up, not built
// this session.
Rectangle {
    id: root

    readonly property bool hasData: !Weather.loading && !Weather.hasError && !isNaN(Weather.currentTemp)

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

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    RowLayout {
        anchors.centerIn: parent
        spacing: 16

        Text {
            text: root.hasData ? root.iconFor(Weather.weatherCode) : "cloud_off"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 40
            color: Colors.primary
        }

        ColumnLayout {
            spacing: 2

            Text {
                text: root.hasData ? Math.round(Weather.currentTemp) + "°C" : "—"
                color: Colors.text
                font.pixelSize: 22
                font.bold: true
            }

            Text {
                text: root.hasData ? root.descriptionFor(Weather.weatherCode) : (Weather.hasError ? "Unavailable" : "Loading…")
                color: Colors.textMuted
                font.pixelSize: 12
            }
        }
    }
}
