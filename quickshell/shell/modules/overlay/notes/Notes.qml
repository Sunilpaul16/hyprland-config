import QtQuick
import Quickshell.Io
import "../"
import "../../../services"
import "../../../components"

// Sticky note widget
OverlayWidget {
    id: root

    identifier: "notes"
    label: "Notes"
    resizable: true
    minWidth: 180
    minHeight: 120
    storedWidth: 300
    storedHeight: 220

    Flickable {
        anchors.fill: parent
        anchors.margins: Motion.spacing.small
        contentWidth: width
        contentHeight: editor.contentHeight
        clip: true
        interactive: root.editing

        TextEdit {
            id: editor
            width: parent.width
            wrapMode: TextEdit.Wrap
            color: Colors.text
            font.family: Fonts.interfaceFamily
            font.pixelSize: Motion.fontSize.body
            selectionColor: Colors.primary
            selectedTextColor: Colors.textOnPrimary
            readOnly: !root.editing
            activeFocusOnPress: root.editing

            onTextChanged: if (notesFile.ready && !notesFile.applying) writeTimer.restart()

            // Empty-state hint
            StyledText {
                anchors.fill: parent
                visible: editor.text.length === 0
                text: "Notes"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.body
            }
        }
    }

    // Debounced write
    Timer {
        id: writeTimer
        interval: 400
        repeat: false
        onTriggered: notesFile.setText(editor.text)
    }

    FileView {
        id: notesFile
        path: Directories.notesFile
        watchChanges: true
        printErrors: false

        property bool ready: false
        property bool applying: false

        onFileChanged: reloadTimer.restart()
        onLoaded: applyTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                notesFile.ready = true;
        }
    }

    // Debounced reload
    Timer {
        id: reloadTimer
        interval: 50
        repeat: false
        onTriggered: notesFile.reload()
    }

    // Apply after read
    Timer {
        id: applyTimer
        interval: 50
        repeat: false
        onTriggered: {
            const disk = notesFile.text();
            if (editor.text !== disk) {
                notesFile.applying = true;
                editor.text = disk;
                notesFile.applying = false;
            }
            notesFile.ready = true;
        }
    }
}
