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
    property int maxPillWidth: 330

    readonly property int currentIndex: root.options.findIndex(o => o.value === root.current)
    readonly property string displayText: root.options.length === 0 ? root.value : (root.options[root.currentIndex]?.label ?? root.current)

    signal clicked
    signal selected(string v)

    implicitWidth: Math.min(root.maxPillWidth,
        labelMetrics.advanceWidth + glyph.implicitWidth
            + Motion.spacing.small + 16 * 2)
    implicitHeight: 34
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.maximumWidth: root.maxPillWidth
    radius: height / 2

    color: hover.containsMouse ? Colors.secondaryContainer : Colors.background
    scale: hover.pressed ? 0.96 : 1

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    Behavior on scale { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    TextMetrics {
        id: labelMetrics
        font: label.font
        text: root.displayText
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: Motion.spacing.small

        StyledText {
            id: label
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.displayText
            font.pixelSize: Motion.fontSize.subhead
            elide: Text.ElideRight
        }

        MaterialIcon {
            id: glyph
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
