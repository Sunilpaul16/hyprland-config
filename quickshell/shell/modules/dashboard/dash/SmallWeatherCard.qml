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

    implicitHeight: weatherRow.implicitHeight + 40

    RowLayout {
        id: weatherRow

        anchors.centerIn: parent
        spacing: 20

        Text {
            text: root.hasData ? Weather.iconFor(Weather.weatherCode) : "cloud_off"
            font.family: "Material Symbols Rounded"
            font.pixelSize: Config.dashboardWeatherIconSize
            color: Colors.primary
        }

        ColumnLayout {
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.hasData ? Math.round(Weather.currentTemp) + "°C" : "—"
                color: Colors.primary
                font.pixelSize: Config.dashboardWeatherTempSize
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: root.width - Config.dashboardWeatherIconSize - 60
                text: root.hasData ? Weather.descriptionFor(Weather.weatherCode) : (Weather.hasError ? "Unavailable" : "Loading…")
                color: Colors.text
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }
}
