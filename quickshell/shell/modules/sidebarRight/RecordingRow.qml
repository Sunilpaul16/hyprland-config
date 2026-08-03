import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"

// Recording row
RowLayout {
    id: root

    required property var modelData
    property bool confirmingDelete: false

    Layout.fillWidth: true
    spacing: Motion.spacing.tiny

    StyledText {
        Layout.fillWidth: true
        text: root.confirmingDelete ? "Delete this recording?" : Recordings.displayName(root.modelData.name)
        color: root.confirmingDelete ? Colors.error : Colors.textMuted
        font.pixelSize: Motion.fontSize.body
        elide: Text.ElideRight
    }

    // Normal actions (play/reveal/delete)
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

    // Confirm delete
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
