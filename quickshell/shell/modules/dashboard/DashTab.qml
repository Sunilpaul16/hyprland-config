pragma ComponentBehavior: Bound

import "dash"
import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"

// Dashboard tab: 6-card grid (User / Weather / DateTime / Calendar / Resources / Media)
Item {
    id: root

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid

        anchors.fill: parent
        columns: 6
        rowSpacing: 12
        columnSpacing: 12

        // Weather spans the DateTime + part of the Calendar column beneath it
        SmallWeatherCard {
            Layout.row: 0
            Layout.column: 0
            Layout.columnSpan: 2
            Layout.preferredWidth: Config.dashboard.weather.width
            Layout.fillHeight: true
        }

        // Content-sized, not stretched — narrower than Weather above it
        DateTimeCard {
            Layout.row: 1
            Layout.column: 0
            Layout.fillHeight: true
        }

        // User spans further right than Calendar, but starts further right too
        UserCard {
            Layout.row: 0
            Layout.column: 2
            Layout.columnSpan: 3
            Layout.preferredWidth: Config.dashboard.user.width
            Layout.fillHeight: true
        }

        // Starts one column left of User — reads wider / left-shifted vs. User above it
        CalendarCard {
            Layout.row: 1
            Layout.column: 1
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 340
        }

        ResourcesCard {
            Layout.row: 1
            Layout.column: 4
            Layout.preferredWidth: implicitWidth
            Layout.fillHeight: true
        }

        // Media card spans both rows
        MediaCard {
            Layout.row: 0
            Layout.column: 5
            Layout.rowSpan: 2
            Layout.preferredWidth: Config.dashboard.media.cardWidth
            Layout.fillHeight: true
        }
    }

    // Big stacked HH / MM digital clock
    component DateTimeCard: Rectangle {
        radius: Motion.rounding.large
        color: Colors.layer
        border.width: 1
        border.color: Colors.outline
        clip: true
        // Fixed width so this stays narrower than Weather above it
        // instead of stretching to match the column
        implicitWidth: Config.dashboard.clock.width
        implicitHeight: clockContent.implicitHeight + 32

        ColumnLayout {
            id: clockContent

            anchors.centerIn: parent
            spacing: -6

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.hourStr
                font.pixelSize: Config.dashboard.clock.fontSize
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "•••"
                color: Colors.primary
                font.pixelSize: Math.round(Config.dashboard.clock.fontSize * 0.5)
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.minuteStr
                font.pixelSize: Config.dashboard.clock.fontSize
                font.bold: true
            }

            StyledText {
                Layout.topMargin: 6
                Layout.alignment: Qt.AlignHCenter
                visible: Time.use12Hour
                text: Time.amPmStr
                color: Colors.primary
                font.pixelSize: Math.round(Config.dashboard.clock.fontSize * 0.43)
                font.bold: true
            }

            StyledText {
                Layout.topMargin: 10
                Layout.alignment: Qt.AlignHCenter
                text: Time.dateStr
                color: Colors.textMuted
                font.pixelSize: 12
            }
        }
    }

    // Full month grid: prev/next navigation, jump-to-today, current-day highlight
    component CalendarCard: Rectangle {
        radius: Motion.rounding.large
        color: Colors.layer
        border.width: 1
        border.color: Colors.outline
        implicitHeight: cal.implicitHeight + 32

        CalendarGrid {
            id: cal

            anchors.fill: parent
            anchors.margins: 16
            cellSize: 26
            // True circle on the centred 26x26 marker
            dayRadius: cellSize / 2
        }
    }
}
