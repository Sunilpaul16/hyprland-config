pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Weather tab: header, hero card, detail cards, 7-day forecast strip — auto-geolocated only, no manual location config yet
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

                StyledText {
                    text: Weather.city.length > 0 ? Weather.city : "Loading…"
                    font.pixelSize: 24
                    font.bold: true
                }

                StyledText {
                    text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.label
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
            radius: Motion.rounding.hero
            color: Colors.layer
            border.width: 1
            border.color: Colors.outline

            RowLayout {
                id: heroRow
                anchors.centerIn: parent
                spacing: 24

                MaterialIcon {
                    text: root.hasCurrent ? Weather.iconFor(Weather.weatherCode) : "cloud_off"
                    font.pixelSize: 72
                    color: Colors.primary
                }

                ColumnLayout {
                    spacing: -4

                    StyledText {
                        text: root.hasCurrent ? Math.round(Weather.currentTemp) + Weather.unitSymbol : "—"
                        font.pixelSize: 48
                        font.bold: true
                    }

                    StyledText {
                        Layout.topMargin: 8
                        text: root.hasCurrent ? Weather.descriptionFor(Weather.weatherCode) : (Weather.hasError ? "Unavailable" : "Loading…")
                        color: Colors.textMuted
                        font.pixelSize: Motion.fontSize.large
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
                value: root.hasCurrent && !isNaN(Weather.feelsLike) ? Math.round(Weather.feelsLike) + Weather.unitSymbol : "--"
            }

            DetailCard {
                iconName: "air"
                label: "Wind"
                value: root.hasCurrent && !isNaN(Weather.windSpeed) ? Math.round(Weather.windSpeed) + " km/h" : "--"
            }
        }

        // 7-day forecast strip
        StyledText {
            Layout.topMargin: 4
            visible: root.hasForecast
            text: "7-Day Forecast"
            font.pixelSize: Motion.fontSize.subhead
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
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.hasForecast
            text: Weather.hasError ? "Forecast unavailable" : "Loading forecast…"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.body
        }
    }

    component WeatherStat: RowLayout {
        id: stat

        required property string iconName
        required property string label
        required property string value

        spacing: 8

        MaterialIcon {
            text: stat.iconName
            font.pixelSize: Motion.fontSize.xlarge
            color: Colors.primary
        }

        ColumnLayout {
            spacing: -2

            StyledText {
                text: stat.label
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.small
            }

            StyledText {
                text: stat.value
                font.pixelSize: Motion.fontSize.label
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
        radius: Motion.rounding.nested
        color: Colors.layer
        border.width: 1
        border.color: Colors.outline

        RowLayout {
            anchors.centerIn: parent
            spacing: 12

            MaterialIcon {
                text: card.iconName
                font.pixelSize: 24
                color: Colors.primary
            }

            ColumnLayout {
                spacing: -2

                StyledText {
                    text: card.label
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.small
                }

                StyledText {
                    text: card.value
                    font.pixelSize: Motion.fontSize.subhead
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

        radius: Motion.rounding.nested
        color: Colors.layer
        border.width: 1
        border.color: Colors.outline
        implicitWidth: dayContent.implicitWidth + 24
        implicitHeight: dayContent.implicitHeight + 24

        ColumnLayout {
            id: dayContent

            anchors.centerIn: parent
            spacing: 6

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: dayCard.dayIndex === 0 ? "Today" : new Date(dayCard.date).toLocaleDateString(Qt.locale(), "ddd")
                color: Colors.primary
                font.pixelSize: Motion.fontSize.label
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: new Date(dayCard.date).toLocaleDateString(Qt.locale(), "MMM d")
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.small
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: Weather.iconFor(dayCard.weatherCode)
                font.pixelSize: 28
                color: Colors.primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Math.round(dayCard.minTemp) + "° / " + Math.round(dayCard.maxTemp) + "°"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.body
                font.bold: true
            }
        }
    }
}
