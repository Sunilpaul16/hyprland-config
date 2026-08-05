import QtQuick
import "../../services"
import "../../components"

// Draggable widget frame
MouseArea {
    id: root

    required property string identifier
    required property Item canvas
    property string label: ""
    property bool showBackground: true

    // Sized by drag, not content
    property bool resizable: false
    property int minWidth: 120
    property int minHeight: 80
    property int storedWidth: 260
    property int storedHeight: 180

    default property alias widgetContent: holder.data

    readonly property var entry: OverlayState.entry(root.identifier)
    readonly property bool pinned: root.entry.pinned ?? false
    readonly property bool editing: OverlayState.open

    visible: root.editing || root.pinned
    implicitWidth: root.resizable ? root.storedWidth : holder.childrenRect.width
    implicitHeight: root.resizable ? root.storedHeight : holder.childrenRect.height

    hoverEnabled: root.editing
    acceptedButtons: root.editing ? Qt.LeftButton : Qt.NoButton
    cursorShape: root.editing ? (root.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor
    drag.target: root.editing ? root : undefined

    // Restore once sized
    property bool restored: false

    function restore(): void {
        if (root.restored || root.width <= 0 || root.height <= 0)
            return;
        if ((root.canvas?.width ?? 0) <= 0 || (root.canvas?.height ?? 0) <= 0)
            return;
        root.restored = true;
        if (root.resizable) {
            root.storedWidth = Math.max(root.minWidth, root.entry.w ?? root.storedWidth);
            root.storedHeight = Math.max(root.minHeight, root.entry.h ?? root.storedHeight);
        }
        if (root.entry.x === undefined || root.entry.y === undefined) {
            root.center();
            return;
        }
        root.x = root.entry.x;
        root.y = root.entry.y;
    }

    function saveGeometry(): void {
        OverlayState.update(root.identifier, {
            x: Math.round(root.x),
            y: Math.round(root.y),
            w: root.storedWidth,
            h: root.storedHeight
        });
    }

    Component.onCompleted: root.restore()
    onWidthChanged: root.restore()
    onHeightChanged: root.restore()

    Connections {
        target: root.canvas
        function onWidthChanged(): void {
            root.restore();
        }
        function onHeightChanged(): void {
            root.restore();
        }
    }

    onReleased: root.saveGeometry()

    function center(): void {
        root.x = Math.round((root.canvas.width - root.width) / 2);
        root.y = Math.round((root.canvas.height - root.height) / 2);
        root.saveGeometry();
    }

    Connections {
        target: OverlayState
        function onRequestCenter(identifier: string): void {
            if (identifier === root.identifier)
                root.center();
        }
    }

    // Widget surface
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Motion.spacing.normal
        radius: Motion.rounding.card
        color: Colors.layerOpaque
        visible: root.showBackground
    }

    // Edit outline
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Motion.spacing.normal
        radius: Motion.rounding.card
        color: "transparent"
        border.width: 1
        border.color: root.containsMouse ? Colors.primary : Colors.outline
        opacity: root.editing ? 1 : 0
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
        }
        Behavior on border.color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    Item {
        id: holder
        anchors.fill: parent
    }

    // Resize grip
    MouseArea {
        id: grip
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 18
        height: 18
        visible: root.resizable && root.editing
        cursorShape: Qt.SizeFDiagCursor

        onPositionChanged: event => {
            if (!grip.pressed)
                return;
            const p = grip.mapToItem(root, event.x, event.y);
            root.storedWidth = Math.max(root.minWidth, Math.round(p.x));
            root.storedHeight = Math.max(root.minHeight, Math.round(p.y));
        }
        onReleased: root.saveGeometry()

        MaterialIcon {
            anchors.centerIn: parent
            text: "resize"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.small
        }
    }

    // Widget toolbar
    Row {
        anchors.bottom: parent.top
        anchors.bottomMargin: Motion.spacing.large
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Motion.spacing.tiny
        opacity: root.editing && root.containsMouse ? 1 : 0
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
        }

        IconAction {
            iconName: root.pinned ? "keep" : "keep_off"
            iconColor: root.pinned ? Colors.primary : Colors.text
            onTriggered: OverlayState.update(root.identifier, {
                pinned: !root.pinned
            })
        }

        IconAction {
            iconName: "filter_center_focus"
            onTriggered: root.center()
        }

        IconAction {
            iconName: "close"
            onTriggered: OverlayState.update(root.identifier, {
                open: false
            })
        }
    }
}
