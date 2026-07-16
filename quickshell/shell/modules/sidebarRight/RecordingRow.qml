import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"

// Single recording row: date/time label + play/reveal/delete. Delete asks
// for inline confirmation first (mirrors modules/session/SessionActionButton's
// Yes/Cancel swap -- this shell has no separate modal-overlay system).
RowLayout {
    id: root

    required property var modelData
    property bool confirmingDelete: false

    Layout.fillWidth: true
    spacing: 4

    Text {
        Layout.fillWidth: true
        text: root.confirmingDelete ? "Delete this recording?" : Recordings.displayName(root.modelData.name)
        color: root.confirmingDelete ? Colors.error : Colors.textMuted
        font.pixelSize: 12
        elide: Text.ElideRight
    }

    RowLayout {
        visible: !root.confirmingDelete
        spacing: 0

        IconAction {
            iconName: "play_arrow"
            onTriggered: Quickshell.execDetached(["xdg-open", root.modelData.path])
        }

        IconAction {
            iconName: "folder_open"
            onTriggered: Quickshell.execDetached(["nautilus", "--select", root.modelData.path])
        }

        IconAction {
            iconName: "delete_forever"
            iconColor: Colors.error
            onTriggered: root.confirmingDelete = true
        }
    }

    RowLayout {
        visible: root.confirmingDelete
        spacing: 0

        IconAction {
            iconName: "check"
            iconColor: Colors.error
            onTriggered: {
                Recordings.deleteEntry(root.modelData.path);
                root.confirmingDelete = false;
            }
        }

        IconAction {
            iconName: "close"
            onTriggered: root.confirmingDelete = false
        }
    }
}
