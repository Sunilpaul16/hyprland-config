import QtQuick
import QtQuick.Layouts
import "../../../services"

// Icon + temp + one-line description — compact weather summary.
// See WeatherTab.qml for the full page.
Rectangle {
    id: root

    readonly property bool hasData: !Weather.loading && !Weather.hasError && !isNaN(Weather.currentTemp)

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    RowLayout {
        anchors.centerIn: parent
        spacing: 16

        Text {
            text: root.hasData ? Weather.iconFor(Weather.weatherCode) : "cloud_off"
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
                text: root.hasData ? Weather.descriptionFor(Weather.weatherCode) : (Weather.hasError ? "Unavailable" : "Loading…")
                color: Colors.textMuted
                font.pixelSize: 12
            }
        }
    }
}
