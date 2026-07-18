import QtQuick
import QtQuick.Controls
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
        onWantsUnmute: Audio.unmuteVolume()
        onMoved: newValue => Audio.setVolume(newValue)
    }

    VolumeSlider {
        icon: root.micIcon
        value: Audio.sourceVolume
        muted: Audio.micMuted
        onWheelUp: Audio.incrementSourceVolume()
        onWheelDown: Audio.decrementSourceVolume()
        onWantsUnmute: Audio.unmuteSourceVolume()
        onMoved: newValue => Audio.setSourceVolume(newValue)
    }

    // Vertical fill track — click/drag to set an absolute value, scroll to
    // step. Built on QtQuick.Templates' Slider (via QtQuick.Controls, same
    // base caelestia's FilledSlider uses) for real press/move/release
    // handling, restyled to this file's existing bottom-anchored-fill look
    // rather than caelestia's own visual treatment.
    component VolumeSlider: Item {
        id: slider

        required property string icon
        required property real value
        required property bool muted

        // Value from the previous drag tick — lets onMoved tell an upward
        // move from a downward one, updated every tick during a gesture
        property real lastDragValue: value

        signal wheelUp
        signal wheelDown
        signal wantsUnmute
        signal moved(real newValue)

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

        Slider {
            id: control

            anchors.top: iconText.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            padding: 0

            orientation: Qt.Vertical
            from: 0
            to: 1
            value: slider.value

            onMoved: {
                if (slider.muted && control.value > slider.lastDragValue)
                    slider.wantsUnmute();
                slider.lastDragValue = control.value;
                slider.moved(control.value);
            }
            onPressedChanged: {
                if (pressed)
                    slider.lastDragValue = slider.value;
                else
                    control.value = Qt.binding(() => slider.value);
            }

            background: Rectangle {
                id: track
                x: control.leftPadding + control.availableWidth / 2 - width / 2
                width: 8
                height: control.availableHeight
                radius: width / 2
                color: Colors.surface

                // Fill — driven straight off slider.value (not
                // control.visualPosition, though they're equivalent here)
                // so it stays correct whether driven by drag, scroll, or
                // an external change while the panel's open
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    radius: width / 2
                    height: parent.height * Math.max(0, Math.min(1, slider.value))
                    color: slider.muted ? Colors.textMuted : Colors.primary

                    Behavior on height { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                }
            }

            handle: Rectangle {
                x: control.leftPadding + control.availableWidth / 2 - width / 2
                y: (control.availableHeight - height) * (1 - Math.max(0, Math.min(1, slider.value)))
                width: 14
                height: 14
                radius: 7
                color: control.pressed ? Colors.text : Colors.primary
            }
        }

        // Wheel-only overlay — acceptedButtons: NoButton lets press/drag
        // fall through to the Slider beneath undisturbed
        MouseArea {
            anchors.fill: control
            acceptedButtons: Qt.NoButton
            onWheel: event => {
                if (event.angleDelta.y > 0)
                    slider.wheelUp();
                else if (event.angleDelta.y < 0)
                    slider.wheelDown();
            }
        }
    }
}
