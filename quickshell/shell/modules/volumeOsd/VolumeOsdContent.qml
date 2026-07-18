import QtQuick
import "../../services"
import "../sidebarRight"

// Speaker + mic vertical sliders — right-edge drawer content
Column {
    id: root

    spacing: 16

    readonly property string speakerIcon: {
        if (Audio.muted)
            return "no_sound";
        if (Audio.volume >= 0.5)
            return "volume_up";
        if (Audio.volume > 0)
            return "volume_down";
        return "volume_mute";
    }
    readonly property string micIcon: (!Audio.micMuted && Audio.sourceVolume > 0) ? "mic" : "mic_off"

    VolumeSlider {
        icon: root.speakerIcon
        value: Audio.volume
        muted: Audio.muted
        onWheelUp: Audio.incrementVolume()
        onWheelDown: Audio.decrementVolume()
    }

    VolumeSlider {
        icon: root.micIcon
        value: Audio.sourceVolume
        muted: Audio.micMuted
        onWheelUp: Audio.incrementSourceVolume()
        onWheelDown: Audio.decrementSourceVolume()
    }

    // Vertical fill track, scroll to adjust
    component VolumeSlider: Item {
        id: slider

        required property string icon
        required property real value
        required property bool muted

        signal wheelUp
        signal wheelDown

        implicitWidth: 40
        implicitHeight: 140

        MaterialIcon {
            id: iconText
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: slider.icon
            color: Colors.text
            font.pixelSize: 18
        }

        // Track
        Rectangle {
            id: track
            anchors.top: iconText.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 8
            radius: width / 2
            color: Colors.surface

            // Fill
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                radius: width / 2
                height: parent.height * Math.max(0, Math.min(1, slider.value))
                color: slider.muted ? Colors.textMuted : Colors.primary

                Behavior on height { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
            }
        }

        MouseArea {
            anchors.fill: parent
            onWheel: event => {
                if (event.angleDelta.y > 0)
                    slider.wheelUp();
                else if (event.angleDelta.y < 0)
                    slider.wheelDown();
            }
        }
    }
}
