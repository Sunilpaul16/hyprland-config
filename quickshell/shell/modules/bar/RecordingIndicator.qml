import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Recording indicator widget
Item {
    id: root

    visible: Recorder.active
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    // Dot + timer label
    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Blinking dot
        Rectangle {
            id: dot
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 10
            implicitHeight: 10
            radius: width / 2
            color: Colors.recording

            SequentialAnimation on opacity {
                running: Recorder.active
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.3; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.3; to: 1; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Recorder.elapsedLabel
            font.pixelSize: Motion.fontSize.body
        }
    }

    // Click to stop recording
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Recorder.stop()
    }
}
