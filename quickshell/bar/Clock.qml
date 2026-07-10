import QtQuick

// Single-line "HH:mm", driven by the shared Time singleton (see Time.qml)
// instead of a private SystemClock. Upstream's caelestia-shell Clock.qml
// stacks hour/minute across two lines with a tertiary-colour background
// pill, an optional calendar icon, and a weekday/day row above -- built for
// a tall standalone widget. Our bar's SectionPill is a flush 32px-tall
// single-line pill (see RecordingIndicator's Text for the same pattern), so
// a single Text bound to Time.timeStr fits the existing layout instead of
// porting that stacked layout.
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
