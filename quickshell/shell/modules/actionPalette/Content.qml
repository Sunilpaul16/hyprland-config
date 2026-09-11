import QtQuick
import "../../services"
import "../../components"

Item {
    id: content

    readonly property var results: ActionPaletteState.query(input.text)
    readonly property int panelWidth: 640
    readonly property int rowHeight: 58
    readonly property int visibleRows: Math.max(1, Math.min(8, results.length))

    implicitWidth: panelWidth
    implicitHeight: 40 + 50 + 14 + visibleRows * rowHeight

    function activateCurrent(): void {
        const action = results[list.currentIndex];
        if (!action)
            return;
        ActionPaletteState.open = false;
        action.execute();
    }

    Rectangle {
        anchors.fill: parent
        radius: 24
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Colors.panel

        MouseArea { anchors.fill: parent }

        ListView {
            id: list
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: search.top
            anchors.margins: 20
            anchors.bottomMargin: 14
            clip: true
            model: content.results
            currentIndex: count > 0 ? 0 : -1
            onModelChanged: currentIndex = count > 0 ? 0 : -1

            delegate: ActionItem {
                isCurrent: ListView.isCurrentItem
                onActivated: {
                    list.currentIndex = index;
                    content.activateCurrent();
                }
            }
        }

        StyledText {
            anchors.centerIn: list
            visible: content.results.length === 0
            text: "No matching actions"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.title
        }

        Rectangle {
            id: search
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 20
            height: 50
            radius: height / 2
            color: Colors.layer

            MaterialIcon {
                anchors.left: parent.left
                anchors.leftMargin: Motion.spacing.xlarge
                anchors.verticalCenter: parent.verticalCenter
                text: "electric_bolt"
                color: Colors.primary
                font.pixelSize: Motion.fontSize.large
            }

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 46
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0
                text: FocusMode.enabled ? `Search actions · focus ${FocusMode.remainingLabel}` : "Search actions and scenes…"
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.title
            }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 46
                anchors.rightMargin: 20
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.text
                font.pixelSize: Motion.fontSize.title
                clip: true
                focus: true

                Keys.onEscapePressed: ActionPaletteState.open = false
                Keys.onReturnPressed: content.activateCurrent()
                Keys.onEnterPressed: content.activateCurrent()
                Keys.onUpPressed: list.decrementCurrentIndex()
                Keys.onDownPressed: list.incrementCurrentIndex()
            }
        }
    }

    Connections {
        target: ActionPaletteState
        function onOpenChanged(): void {
            if (ActionPaletteState.open) {
                input.text = "";
                input.forceActiveFocus();
            }
        }
    }

    Corner {
        anchors { right: parent.left; bottom: parent.bottom }
        size: Motion.cornerSize
        color: Colors.panel
        corner: "bottomRight"
    }

    Corner {
        anchors { left: parent.right; bottom: parent.bottom }
        size: Motion.cornerSize
        color: Colors.panel
        corner: "bottomLeft"
    }
}
