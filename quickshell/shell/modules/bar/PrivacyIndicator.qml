import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Privacy indicator
Item {
    id: root

    readonly property bool active: Privacy.active
    property bool tooltipVisible: false

    visible: root.active
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Motion.spacing.tiny

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: Privacy.micActive
            text: "mic"
            font.pixelSize: Motion.fontSize.subhead
            color: Colors.recording
        }

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: Privacy.screencastActive
            text: "screen_share"
            font.pixelSize: Motion.fontSize.subhead
            color: Colors.recording
        }
    }

    // Hover tooltip
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.tooltipVisible = true
        onExited: root.tooltipVisible = false
    }

    PopupToolTip {
        hoverTarget: root
        shown: root.tooltipVisible
        text: {
            const parts = [];
            if (Privacy.micActive)
                parts.push(Privacy.micCount === 1 ? "Microphone in use" : `Microphone in use by ${Privacy.micCount}`);
            if (Privacy.screencastActive)
                parts.push(Privacy.screencastCount === 1 ? "Screen being shared" : `Screen shared with ${Privacy.screencastCount}`);
            return parts.join("\n");
        }
    }
}
