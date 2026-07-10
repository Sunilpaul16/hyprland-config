import QtQuick
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../"

// One row in the ">clip" clipboard-history list -- same chrome as AppItem
// (icon slot + highlight rectangle + Colors.qml theming) but up to 3 wrapped
// lines instead of AppItem's single name line, since clipboard snippets
// often need more than one line to tell apart. Text entries keep the 📋
// glyph; image entries get a real thumbnail instead of a placeholder glyph,
// decoded lazily -- same pattern as end-4's CliphistImage.qml: decode into
// Cliphist.decodeDir the moment this row mounts, delete the file the moment
// it unmounts. No caching across mounts, on purpose (see Cliphist.qml) --
// scrolling back re-decodes, but that keeps the scratch dir from ever
// accumulating regardless of how much history gets scrolled through.
//
// A third shape (modelData.isAction, see Content.qml's clipActionRow) is a
// single synthetic row for "/token" actions like "/clear" -- no entry/icon
// glyph/thumbnail logic applies to it, just its own icon+label, styled
// outlined/dimmer rather than the normal primary-fill selection highlight
// since Colors.qml has no dedicated error/warning tone to borrow instead.
Item {
    id: root

    required property var modelData
    required property bool isCurrent

    readonly property bool isAction: !!root.modelData.isAction

    width: ListView.view.width
    height: 76

    signal activated
    signal deleteRequested

    readonly property string thumbPath: root.isAction ? "" : `${Cliphist.decodeDir}/${Cliphist.entryId(root.modelData.entry)}`
    property string thumbSource: ""

    Component.onCompleted: {
        if (!root.isAction && root.modelData.isImage)
            decodeProc.running = true;
    }

    Component.onDestruction: {
        if (!root.isAction && root.modelData.isImage)
            Quickshell.execDetached(["bash", "-c", `rm -f '${root.thumbPath}'`]);
    }

    // Stdin goes straight to the child (Process.write), same as
    // Cliphist.qml's copy()/deleteEntry() -- and `stdinEnabled` must go
    // true->write->false around it or `cliphist decode` hangs waiting for
    // EOF forever (see Cliphist.qml's header comment). This Process only
    // ever runs once per mount, so no need to reset stdinEnabled back to
    // true before running like the reusable singleton Processes do.
    Process {
        id: decodeProc
        command: ["bash", "-c", `[ -f '${root.thumbPath}' ] || ${Cliphist.cliphistBinary} decode > '${root.thumbPath}'`]
        stdinEnabled: true
        onStarted: {
            decodeProc.write(root.modelData.entry + "\n");
            decodeProc.stdinEnabled = false;
        }
        onExited: exitCode => {
            if (exitCode === 0)
                root.thumbSource = root.thumbPath;
            else
                console.error("[ClipItem] thumbnail decode failed for", root.modelData.entry, "code", exitCode);
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: root.isAction ? (root.isCurrent ? Colors.surface : "transparent") : (root.isCurrent ? Colors.primary : "transparent")
        border.width: root.isAction ? 1 : 0
        border.color: Colors.outline

        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Item {
                id: iconSlot
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36

                Text {
                    anchors.centerIn: parent
                    visible: root.isAction || !root.modelData.isImage
                    text: root.isAction ? root.modelData.icon : "\u{1F4CB}"
                    font.pixelSize: 20
                }

                Rectangle {
                    id: thumbClip
                    anchors.fill: parent
                    radius: 8
                    color: Colors.surface
                    visible: !root.isAction && root.modelData.isImage

                    layer.enabled: !root.isAction && root.modelData.isImage
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: thumbClip.width
                            height: thumbClip.height
                            radius: thumbClip.radius
                        }
                    }

                    Image {
                        anchors.fill: parent
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        visible: root.thumbSource.length > 0
                        source: root.thumbSource.length > 0 ? Qt.resolvedUrl(root.thumbSource) : ""
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - iconSlot.width - parent.spacing
                text: root.isAction ? root.modelData.label : root.modelData.text
                color: root.isAction ? Colors.text : (root.isCurrent ? Colors.background : Colors.text)
                font.pixelSize: 13
                font.bold: root.isAction
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: mouse => {
            if (mouse.modifiers & Qt.ShiftModifier)
                root.deleteRequested();
            else
                root.activated();
        }
    }
}
