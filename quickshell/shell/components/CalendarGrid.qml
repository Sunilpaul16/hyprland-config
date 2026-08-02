import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services"

// Month calendar grid — draws no card chrome; the caller owns its surface
Item {
    id: root

    // Cells stretch to fill their column, so this is row height and marker size, not width
    property int cellSize: 26
    property int cellSpacing: 4
    property int dayRadius: Motion.rounding.small
    property bool showTodayButton: true
    // Space reserved at the head of the nav row for a caller's own button
    property int headerLeftInset: 0

    // Viewed month
    property date viewDate: new Date()
    readonly property int viewMonth: viewDate.getMonth()
    readonly property int viewYear: viewDate.getFullYear()
    readonly property bool onCurrentMonth: {
        const now = new Date();
        return viewMonth === now.getMonth() && viewYear === now.getFullYear();
    }

    // Changes only at midnight; binding delegates to Time.date would re-evaluate all 42 every second
    readonly property string todayKey: Time.format("yyyy-MM-dd")

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    function goToToday(): void {
        root.viewDate = new Date();
    }

    function stepMonth(delta: int): void {
        root.viewDate = new Date(root.viewYear, root.viewMonth + delta, 1);
    }

    WheelHandler {
        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.stepMonth(-1);
            else if (event.angleDelta.y < 0)
                root.stepMonth(1);
        }
    }

    // Middle-click jumps back to today
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: root.goToToday()
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        spacing: 8

        // Month navigation + jump-to-today
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Item {
                visible: root.headerLeftInset > 0
                Layout.preferredWidth: root.headerLeftInset
                Layout.preferredHeight: 1
            }

            NavButton {
                glyph: "‹"
                onClicked: root.stepMonth(-1)
            }

            // Clicking the month label also jumps to today
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: monthLabel.implicitHeight + 8
                radius: height / 2
                color: monthArea.containsMouse && !root.onCurrentMonth ? Colors.outline : "transparent"

                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                StyledText {
                    id: monthLabel

                    anchors.centerIn: parent
                    text: root.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    color: Colors.primary
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: monthArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.onCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: root.goToToday()
                }
            }

            NavButton {
                glyph: "›"
                onClicked: root.stepMonth(1)
            }

            Rectangle {
                visible: root.showTodayButton
                implicitWidth: todayLabel.implicitWidth + 16
                implicitHeight: 24
                radius: Motion.rounding.normal
                color: root.onCurrentMonth ? "transparent" : Colors.primary
                border.width: root.onCurrentMonth ? 1 : 0
                border.color: Colors.outline

                StyledText {
                    id: todayLabel

                    anchors.centerIn: parent
                    text: "Today"
                    color: root.onCurrentMonth ? Colors.textMuted : Colors.background
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToToday()
                }
            }
        }

        // Weekday header row
        DayOfWeekRow {
            id: dayRow

            Layout.fillWidth: true
            locale: grid.locale
            spacing: root.cellSpacing

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
            month: root.viewMonth
            year: root.viewYear
            locale: Qt.locale()
            spacing: root.cellSpacing

            // The cell stretches to fill its column, so the marker is a centred child
            delegate: Item {
                id: dayCell

                required property var model

                // JS Date.getDay(): Sunday=0 .. Saturday=6
                readonly property bool isWeekend: {
                    const d = dayCell.model.date.getDay();
                    return d === 0 || d === 6;
                }
                readonly property bool isToday: Qt.formatDate(dayCell.model.date, "yyyy-MM-dd") === root.todayKey

                implicitWidth: root.cellSize
                implicitHeight: root.cellSize

                Rectangle {
                    anchors.centerIn: parent
                    width: root.cellSize
                    height: root.cellSize
                    radius: root.dayRadius
                    color: dayCell.isToday ? Colors.primary : "transparent"
                }

                StyledText {
                    anchors.centerIn: parent
                    text: dayCell.model.day
                    font.pixelSize: 12
                    color: dayCell.isToday ? Colors.textOnPrimary : (dayCell.isWeekend ? Colors.primary : Colors.text)
                    opacity: dayCell.model.month === grid.month ? 1 : 0.35
                }
            }
        }
    }

    component NavButton: Rectangle {
        id: navBtn

        required property string glyph
        signal clicked

        implicitWidth: 26
        implicitHeight: 26
        radius: width / 2
        color: navArea.containsMouse ? Colors.outline : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        StyledText {
            anchors.centerIn: parent
            text: navBtn.glyph
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
