pragma ComponentBehavior: Bound

import "dash"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
        radius: 18
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

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Time.hourStr
                color: Colors.text
                font.pixelSize: Config.dashboard.clock.fontSize
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "•••"
                color: Colors.primary
                font.pixelSize: Math.round(Config.dashboard.clock.fontSize * 0.5)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Time.minuteStr
                color: Colors.text
                font.pixelSize: Config.dashboard.clock.fontSize
                font.bold: true
            }

            Text {
                Layout.topMargin: 6
                Layout.alignment: Qt.AlignHCenter
                visible: Time.use12Hour
                text: Time.amPmStr
                color: Colors.primary
                font.pixelSize: Math.round(Config.dashboard.clock.fontSize * 0.43)
                font.bold: true
            }

            Text {
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
        id: calCard

        property date viewDate: new Date()
        readonly property int viewMonth: viewDate.getMonth()
        readonly property int viewYear: viewDate.getFullYear()
        readonly property bool onCurrentMonth: {
            const now = new Date();
            return viewMonth === now.getMonth() && viewYear === now.getFullYear();
        }

        radius: 18
        color: Colors.layer
        border.width: 1
        border.color: Colors.outline
        implicitHeight: calContent.implicitHeight + 32

        // Wheel to change month, middle-click anywhere to jump to today
        WheelHandler {
            onWheel: event => {
                if (event.angleDelta.y > 0)
                    calCard.viewDate = new Date(calCard.viewYear, calCard.viewMonth - 1, 1);
                else if (event.angleDelta.y < 0)
                    calCard.viewDate = new Date(calCard.viewYear, calCard.viewMonth + 1, 1);
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.MiddleButton
            onClicked: calCard.viewDate = new Date()
        }

        ColumnLayout {
            id: calContent

            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            // Month navigation + jump-to-today
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                NavButton {
                    glyph: "‹"
                    onClicked: calCard.viewDate = new Date(calCard.viewYear, calCard.viewMonth - 1, 1)
                }

                // Clicking the month label also jumps to today (caelestia's affordance)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: monthLabel.implicitHeight + 8
                    radius: height / 2
                    color: monthArea.containsMouse && !calCard.onCurrentMonth ? Colors.outline : "transparent"

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    Text {
                        id: monthLabel

                        anchors.centerIn: parent
                        text: calCard.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                        color: Colors.primary
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        id: monthArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: calCard.onCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: calCard.viewDate = new Date()
                    }
                }

                NavButton {
                    glyph: "›"
                    onClicked: calCard.viewDate = new Date(calCard.viewYear, calCard.viewMonth + 1, 1)
                }

                Rectangle {
                    id: todayButton

                    implicitWidth: todayLabel.implicitWidth + 16
                    implicitHeight: 24
                    radius: 12
                    color: calCard.onCurrentMonth ? "transparent" : Colors.primary
                    border.width: calCard.onCurrentMonth ? 1 : 0
                    border.color: Colors.outline

                    Text {
                        id: todayLabel
                        anchors.centerIn: parent
                        text: "Today"
                        color: calCard.onCurrentMonth ? Colors.textMuted : Colors.background
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calCard.viewDate = new Date()
                    }
                }
            }

            DayOfWeekRow {
                id: dayRow

                Layout.fillWidth: true
                locale: grid.locale

                delegate: Text {
                    required property var model

                    // Qt::DayOfWeek: Monday=1 .. Sunday=7
                    readonly property bool isWeekend: model.day === 6 || model.day === 7

                    horizontalAlignment: Text.AlignHCenter
                    text: model.shortName
                    color: isWeekend ? Colors.primary : Colors.textMuted
                    font.pixelSize: 11
                }
            }

            MonthGrid {
                id: grid

                Layout.fillWidth: true
                Layout.fillHeight: true
                month: calCard.viewMonth
                year: calCard.viewYear
                locale: Qt.locale()
                spacing: 4

                delegate: Rectangle {
                    id: dayCell

                    required property var model

                    // JS Date.getDay(): Sunday=0 .. Saturday=6
                    readonly property bool isWeekend: {
                        const d = dayCell.model.date.getDay();
                        return d === 0 || d === 6;
                    }

                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: dayCell.model.today ? Colors.primary : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.model.day
                        font.pixelSize: 12
                        color: dayCell.model.today ? Colors.background : (dayCell.isWeekend ? Colors.primary : Colors.text)
                        opacity: dayCell.model.month === grid.month ? 1 : 0.35
                    }
                }
            }
        }
    }

    component NavButton: Rectangle {
        id: navBtn

        required property string glyph
        signal clicked()

        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        color: navArea.containsMouse ? Colors.outline : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        Text {
            anchors.centerIn: parent
            text: navBtn.glyph
            color: Colors.text
            font.pixelSize: 15
        }

        MouseArea {
            id: navArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: navBtn.clicked()
        }
    }
}
