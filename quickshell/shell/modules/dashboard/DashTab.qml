pragma ComponentBehavior: Bound

import "dash"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../services"

// Dashboard tab: 6-card grid (User / Weather / DateTime / Calendar / Resources / Media)
Item {
    id: root

    GridLayout {
        anchors.fill: parent
        columns: 6
        rowSpacing: 12
        columnSpacing: 12

        UserCard {
            Layout.row: 0
            Layout.column: 0
            Layout.rowSpan: 2
            Layout.preferredWidth: 190
            Layout.fillHeight: true
        }

        // Weather card (stub — real content once Weather service exists)
        StubCard {
            label: "Weather"

            Layout.row: 0
            Layout.column: 1
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.preferredHeight: 120
        }

        DateTimeCard {
            Layout.row: 1
            Layout.column: 1
            Layout.preferredWidth: 150
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        CalendarCard {
            Layout.row: 1
            Layout.column: 2
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 340
        }

        ResourcesCard {
            Layout.row: 1
            Layout.column: 4
            Layout.preferredWidth: 80
            Layout.fillHeight: true
        }

        MediaCard {
            Layout.row: 0
            Layout.column: 5
            Layout.rowSpan: 2
            Layout.preferredWidth: 210
            Layout.fillHeight: true
        }
    }

    // Generic labeled placeholder for cards without real content yet
    component StubCard: Rectangle {
        id: stub

        required property string label

        radius: 18
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline

        Text {
            anchors.centerIn: parent
            text: stub.label
            color: Colors.textMuted
            font.pixelSize: 15
        }
    }

    // Big stacked HH / MM digital clock
    component DateTimeCard: Rectangle {
        radius: 18
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline
        clip: true

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Time.hourStr
                color: Colors.primary
                font.pixelSize: 42
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Time.minuteStr
                color: Colors.text
                font.pixelSize: 42
                font.bold: true
            }

            Text {
                Layout.topMargin: 6
                Layout.alignment: Qt.AlignHCenter
                visible: Time.use12Hour
                text: Time.amPmStr
                color: Colors.textMuted
                font.pixelSize: 13
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
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline

        ColumnLayout {
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

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: calCard.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    color: Colors.text
                    font.pixelSize: 14
                    font.bold: true
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

                    horizontalAlignment: Text.AlignHCenter
                    text: model.shortName
                    color: Colors.textMuted
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

                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: dayCell.model.today ? Colors.primary : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.model.day
                        font.pixelSize: 12
                        color: dayCell.model.today ? Colors.background : Colors.text
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
