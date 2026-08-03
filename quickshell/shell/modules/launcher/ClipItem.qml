import QtQuick
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../../services"
import "../../components"


// Clipboard list item
Item {
    id: root

    required property var modelData
    required property bool isCurrent

    // Derived state
    readonly property bool isAction: !!root.modelData.isAction

    width: ListView.view.width
    height: 76

    signal activated
    signal deleteRequested

    readonly property string thumbPath: root.isAction ? "" : `${Cliphist.decodeDir}/${Cliphist.entryId(root.modelData.entry)}`
    property string thumbSource: ""

    // Thumbnail lifecycle
    Component.onCompleted: {
        if (!root.isAction && root.modelData.isImage)
            decodeProc.running = true;
    }

    Component.onDestruction: {
        if (!root.isAction && root.modelData.isImage)
            Quickshell.execDetached(["bash", "-c", `rm -f '${root.thumbPath}'`]);
    }


    // Decode entry thumbnail
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

    // Row background
    Rectangle {
        anchors.fill: parent
        anchors.margins: Motion.spacing.micro
        radius: Motion.rounding.item
        color: root.isAction ? (root.isCurrent ? Colors.layer : "transparent") : (root.isCurrent ? Colors.primary : "transparent")
        border.width: root.isAction ? 1 : 0
        border.color: root.isAction ? Colors.error : Colors.outline

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        // Icon/thumbnail + text
        Row {
            anchors.fill: parent
            anchors.leftMargin: Motion.spacing.large
            anchors.rightMargin: Motion.spacing.large
            spacing: Motion.spacing.large

            // Icon/thumbnail slot
            Item {
                id: iconSlot
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36

                StyledText {
                    anchors.centerIn: parent
                    visible: root.isAction || !root.modelData.isImage
                    text: root.isAction ? root.modelData.icon : "\u{1F4CB}"
                    font.pixelSize: Motion.fontSize.display
                }

                Rectangle {
                    id: thumbClip
                    anchors.fill: parent
                    radius: Motion.rounding.small
                    color: Colors.layer
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

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - iconSlot.width - parent.spacing
                text: root.isAction ? root.modelData.label : root.modelData.text
                color: root.isAction ? Colors.error : (root.isCurrent ? Colors.textOnPrimary : Colors.text)
                font.pixelSize: Motion.fontSize.label
                font.bold: root.isAction
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
    }

    // Click and shift-click
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
