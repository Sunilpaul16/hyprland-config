pragma ComponentBehavior: Bound

import "dash"
import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"

// Dashboard tab grid
Item {
    id: root

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid

        anchors.fill: parent
        columns: 6
        rowSpacing: Motion.spacing.large
        columnSpacing: Motion.spacing.large

        // Weather span
        SmallWeatherCard {
            Layout.row: 0
            Layout.column: 0
            Layout.columnSpan: 2
            Layout.preferredWidth: Config.dashboard.weather.width
            Layout.fillHeight: true
        }

        // Content-sized
        DateTimeCard {
            Layout.row: 1
            Layout.column: 0
            Layout.fillHeight: true
        }

        // User span
        UserCard {
            Layout.row: 0
            Layout.column: 2
            Layout.columnSpan: 3
            Layout.preferredWidth: Config.dashboard.user.width
            Layout.fillHeight: true
        }

        // Calendar span
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

        // Media spans rows
        MediaCard {
            Layout.row: 0
            Layout.column: 5
            Layout.rowSpan: 2
            Layout.preferredWidth: Config.dashboard.media.cardWidth
            Layout.fillHeight: true
        }
    }

    // Digital clock card
    component DateTimeCard: Rectangle {
        radius: Motion.rounding.large
        color: Colors.layer
        border.width: 1
        border.color: Colors.outline
        clip: true
        // Fixed width
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
                Layout.topMargin: Motion.spacing.small
                Layout.alignment: Qt.AlignHCenter
                visible: Time.use12Hour
                text: Time.amPmStr
                color: Colors.primary
                font.pixelSize: Math.round(Config.dashboard.clock.fontSize * 0.43)
                font.bold: true
            }

            StyledText {
                Layout.topMargin: Motion.spacing.medium
                Layout.alignment: Qt.AlignHCenter
                text: Time.dateStr
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.body
            }
        }
    }

    // Calendar card
    component CalendarCard: Rectangle {
        radius: Motion.rounding.large
        color: Colors.layer
        border.width: 1
        border.color: Colors.outline
        implicitHeight: cal.implicitHeight + 32

        CalendarGrid {
            id: cal

            anchors.fill: parent
            anchors.margins: Motion.spacing.xlarge
            cellSize: 26
            // True circle
            dayRadius: cellSize / 2
        }
    }
}
