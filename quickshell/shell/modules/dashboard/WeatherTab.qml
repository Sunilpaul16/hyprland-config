pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"

// Weather tab: header, hero card, detail cards, 7-day forecast strip.
// Auto-geolocated only — manual location config is out of scope for now
// (see INDEX.md backlog).
Item {
    id: root

    readonly property bool hasCurrent: !Weather.loading && !Weather.hasError && !isNaN(Weather.currentTemp)
    readonly property bool hasForecast: Weather.forecast.length > 0
    readonly property bool hasSunTimes: Weather.sunrise !== "--:--" || Weather.sunset !== "--:--"

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content

        anchors.fill: parent
        spacing: 16

        // Header: city + date, sunrise/sunset
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2

                Text {
                    text: Weather.city.length > 0 ? Weather.city : "Loading…"
                    color: Colors.text
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")
                    color: Colors.textMuted
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                visible: root.hasSunTimes
                spacing: 24

                WeatherStat {
                    iconName: "wb_twilight"
                    label: "Sunrise"
                    value: Weather.sunrise
                }

                WeatherStat {
                    iconName: "bedtime"
                    label: "Sunset"
                    value: Weather.sunset
                }
            }
        }

        // Hero card: icon + current temp + description
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: heroRow.implicitHeight + 48
            radius: 28
            color: Colors.surface
            border.width: 1
            border.color: Colors.outline

            RowLayout {
                id: heroRow
                anchors.centerIn: parent
                spacing: 24

                Text {
                    text: root.hasCurrent ? Weather.iconFor(Weather.weatherCode) : "cloud_off"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 72
                    color: Colors.primary
                }

                ColumnLayout {
                    spacing: -4

                    Text {
                        text: root.hasCurrent ? Math.round(Weather.currentTemp) + "°C" : "—"
                        color: Colors.text
                        font.pixelSize: 48
                        font.bold: true
                    }

                    Text {
                        Layout.topMargin: 8
                        text: root.hasCurrent ? Weather.descriptionFor(Weather.weatherCode) : (Weather.hasError ? "Unavailable" : "Loading…")
                        color: Colors.textMuted
                        font.pixelSize: 16
                    }
                }
            }
        }

        // Detail cards: humidity / feels-like / wind speed
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            DetailCard {
                iconName: "water_drop"
                label: "Humidity"
                value: root.hasCurrent && Weather.humidity >= 0 ? Weather.humidity + "%" : "--"
            }

            DetailCard {
                iconName: "thermostat"
                label: "Feels Like"
                value: root.hasCurrent && !isNaN(Weather.feelsLike) ? Math.round(Weather.feelsLike) + "°C" : "--"
            }

            DetailCard {
                iconName: "air"
                label: "Wind"
                value: root.hasCurrent && !isNaN(Weather.windSpeed) ? Math.round(Weather.windSpeed) + " km/h" : "--"
            }
        }

        // 7-day forecast strip
        Text {
            Layout.topMargin: 4
            visible: root.hasForecast
            text: "7-Day Forecast"
            color: Colors.text
            font.pixelSize: 14
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.hasForecast
            spacing: 10

            Repeater {
                model: Weather.forecast

                delegate: ForecastDayCard {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    dayIndex: index
                    date: modelData.date
                    weatherCode: modelData.weatherCode
                    minTemp: modelData.minTemp
                    maxTemp: modelData.maxTemp
                }
            }
        }

        // Forecast placeholder — current data can still be showing above
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.hasForecast
            text: Weather.hasError ? "Forecast unavailable" : "Loading forecast…"
            color: Colors.textMuted
            font.pixelSize: 12
        }
    }

    component WeatherStat: RowLayout {
        id: stat

        required property string iconName
        required property string label
        required property string value

        spacing: 8

        Text {
            text: stat.iconName
            font.family: "Material Symbols Rounded"
            font.pixelSize: 22
            color: Colors.primary
        }

        ColumnLayout {
            spacing: -2

            Text {
                text: stat.label
                color: Colors.textMuted
                font.pixelSize: 11
            }

            Text {
                text: stat.value
                color: Colors.text
                font.pixelSize: 13
                font.bold: true
            }
        }
    }

    component DetailCard: Rectangle {
        id: card

        required property string iconName
        required property string label
        required property string value

        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: 16
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline

        RowLayout {
            anchors.centerIn: parent
            spacing: 12

            Text {
                text: card.iconName
                font.family: "Material Symbols Rounded"
                font.pixelSize: 24
                color: Colors.primary
            }

            ColumnLayout {
                spacing: -2

                Text {
                    text: card.label
                    color: Colors.textMuted
                    font.pixelSize: 11
                }

                Text {
                    text: card.value
                    color: Colors.text
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }
    }

    component ForecastDayCard: Rectangle {
        id: dayCard

        required property int dayIndex
        required property string date
        required property int weatherCode
        required property real minTemp
        required property real maxTemp

        radius: 16
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline
        implicitWidth: dayContent.implicitWidth + 24
        implicitHeight: dayContent.implicitHeight + 24

        ColumnLayout {
            id: dayContent

            anchors.centerIn: parent
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: dayCard.dayIndex === 0 ? "Today" : new Date(dayCard.date).toLocaleDateString(Qt.locale(), "ddd")
                color: Colors.primary
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: new Date(dayCard.date).toLocaleDateString(Qt.locale(), "MMM d")
                color: Colors.textMuted
                font.pixelSize: 11
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Weather.iconFor(dayCard.weatherCode)
                font.family: "Material Symbols Rounded"
                font.pixelSize: 28
                color: Colors.primary
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Math.round(dayCard.minTemp) + "° / " + Math.round(dayCard.maxTemp) + "°"
                color: Colors.textMuted
                font.pixelSize: 12
                font.bold: true
            }
        }
    }
}
