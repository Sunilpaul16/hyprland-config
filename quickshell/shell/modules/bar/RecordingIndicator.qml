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

    // Dot and timer
    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Motion.spacing.small

        // Blinking dot
        Rectangle {
            id: dot
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 10
            implicitHeight: 10
            radius: width / 2
            color: Colors.recording

            SequentialAnimation on opacity {
                running: Recorder.active && !Motion.reduced
                loops: Animation.Infinite
                onRunningChanged: if (!running) dot.opacity = 1
                NumberAnimation { from: 1; to: 0.25; duration: Motion.scaled(600); easing.type: Easing.InQuad }
                NumberAnimation { from: 0.25; to: 1; duration: Motion.scaled(1000); easing.type: Easing.OutQuad }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Recorder.elapsedLabel
            font.pixelSize: Motion.fontSize.body
        }
    }

    // Click stops
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Recorder.stop()
    }
}
