import QtQuick

// Single-line "HH:mm" bound to the shared Time singleton -- caelestia's own
// Clock.qml stacks hour/minute + calendar/weekday for a tall standalone
// widget, but this bar's SectionPill is a flush single-line pill, so one
// Text fits better than porting that layout.
Item {
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        text: Time.timeStr
        color: Colors.text
        font.pixelSize: 16
        font.bold: true
    }
}
