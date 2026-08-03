import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../components"

// Compact weather card
Rectangle {
    id: root

    readonly property bool hasData: !Weather.loading && !Weather.hasError && !isNaN(Weather.currentTemp)

    radius: Motion.rounding.large
    color: Colors.layer
    border.width: 1
    border.color: Colors.outline

    implicitHeight: weatherRow.implicitHeight + 40

    RowLayout {
        id: weatherRow

        anchors.centerIn: parent
        spacing: 20

        MaterialIcon {
            text: root.hasData ? Weather.iconFor(Weather.weatherCode) : "cloud_off"
            font.pixelSize: Config.dashboard.weather.iconSize
            color: Colors.primary
        }

        ColumnLayout {
            spacing: Motion.spacing.micro

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.hasData ? Math.round(Weather.currentTemp) + Weather.unitSymbol : "—"
                color: Colors.primary
                font.pixelSize: Config.dashboard.weather.tempSize
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: root.width - Config.dashboard.weather.iconSize - 60
                text: root.hasData ? Weather.descriptionFor(Weather.weatherCode) : (Weather.hasError ? "Unavailable" : "Loading…")
                font.pixelSize: Motion.fontSize.body
                elide: Text.ElideRight
            }
        }
    }
}
