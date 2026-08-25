import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Dropdown pill
Rectangle {
    id: root

    property string value
    // Trailing glyph
    property string icon: "expand_more"

    // [{ value: "auto", label: "Auto" }, ...]
    property var options: []
    property string current: ""

    readonly property int currentIndex: root.options.findIndex(o => o.value === root.current)
    readonly property string displayText: root.options.length === 0 ? root.value : (root.options[root.currentIndex]?.label ?? root.current)

    signal clicked
    signal selected(string v)

    implicitWidth: layout.implicitWidth + 16 * 2
    implicitHeight: 34
    radius: height / 2

    color: hover.containsMouse ? Colors.secondaryContainer : Colors.background
    scale: hover.pressed ? 0.96 : 1

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    Behavior on scale { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Motion.spacing.small

        StyledText {
            text: root.displayText
            font.pixelSize: Motion.fontSize.subhead
        }

        MaterialIcon {
            text: root.icon
            color: Colors.outline
            font.pixelSize: Motion.fontSize.header
        }
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.options.length === 0) {
                root.clicked();
                return;
            }
            // Unknown lands first
            const next = (root.currentIndex + 1) % root.options.length;
            root.selected(root.options[next].value);
        }
    }
}
