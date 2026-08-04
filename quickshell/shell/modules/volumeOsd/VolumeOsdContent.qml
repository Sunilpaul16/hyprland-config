import QtQuick
import QtQuick.Controls
import "../../services"
import "../../components"

// Volume sliders
Column {
    id: root

    spacing: Motion.spacing.xlarge

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

    // Vertical slider
    component VolumeSlider: Column {
        id: slider

        required property string icon
        required property real value
        required property bool muted

        // Previous drag value
        property real lastDragValue: value

        readonly property int trackWidth: 24

        signal wheelUp
        signal wheelDown
        signal wantsUnmute
        signal moved(real newValue)

        spacing: Motion.spacing.small

        Item {
            id: track

            implicitWidth: slider.trackWidth
            implicitHeight: 140

            Slider {
                id: control

                anchors.fill: parent
                padding: 0

                orientation: Qt.Vertical
                from: 0
                to: Audio.maxVolume
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

                // Track
                background: Rectangle {
                    width: control.availableWidth
                    height: control.availableHeight
                    radius: width / 2
                    color: Colors.layer

                    // Fill
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        radius: parent.radius
                        height: parent.height * Math.max(0, Math.min(1, slider.value))
                        color: slider.muted ? Colors.textMuted : Colors.primary

                        Behavior on height { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                    }
                }

                // Handle
                handle: Rectangle {
                    x: control.leftPadding + control.availableWidth / 2 - width / 2
                    y: (control.availableHeight - height) * (1 - Math.max(0, Math.min(1, slider.value)))
                    width: slider.trackWidth
                    height: slider.trackWidth
                    radius: width / 2
                    color: control.pressed ? Colors.text : (slider.muted ? Colors.textMuted : Colors.primary)

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: slider.icon
                        color: Colors.textOnPrimary
                        font.pixelSize: Motion.fontSize.subhead
                    }
                }
            }

            // Wheel overlay
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

        // Percentage readout
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(slider.value * 100)
            color: slider.muted ? Colors.textMuted : Colors.text
            font.pixelSize: Motion.fontSize.small
        }
    }
}
