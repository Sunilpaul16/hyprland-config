import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Dropdown-style control — current value plus a chevron
// Two modes: `options` empty is a plain button showing `value`; `options` set makes it an enum picker where a click advances and emits selected()
Rectangle {
    id: root

    property string value
    // Trailing glyph — "expand_more" for a select, "chevron_right" for a nav row
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

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 6

        StyledText {
            text: root.displayText
            font.pixelSize: 14
        }

        MaterialIcon {
            text: root.icon
            color: Colors.outline
            font.pixelSize: 18
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
            // Unknown current value lands on the first option rather than nothing
            const next = (root.currentIndex + 1) % root.options.length;
            root.selected(root.options[next].value);
        }
    }
}
