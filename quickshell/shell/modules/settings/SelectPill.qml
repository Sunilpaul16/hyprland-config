import QtQuick
import QtQuick.Layouts
import "../../services"
import "../sidebarRight"

// Dropdown-style control — current value plus a chevron.
//
// Two modes. With `options` empty it is a plain button showing `value`.
// With `options` set it becomes an enum picker over [{value, label}] and a
// click advances to the next one, emitting selected(). Cycling rather than
// opening a menu: these enums have two or three members, and a popup would
// have to escape the panel's own surface to render
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

        Text {
            text: root.displayText
            color: Colors.text
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
