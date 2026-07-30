import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../services"
import "../notifications"

// Notifications card (sidebar) — fills the panel's leftover height so the
// empty-state watermark has room, matching caelestia's NotifDock
Rectangle {
    id: root

    readonly property bool isEmpty: Notifs.list.length === 0

    // Footer pill (end-4's NotificationStatusButton) — full-height rounded ends
    component StatusButton: Rectangle {
        id: sb

        property string glyph: ""
        property string label: ""
        property bool toggled: false
        property bool interactive: true
        signal triggered

        implicitHeight: 36
        radius: height / 2
        color: sb.toggled ? Colors.primary : (sb.interactive && sbArea.containsMouse ? Colors.outline : Colors.background)

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        Text {
            anchors.centerIn: parent
            text: sb.glyph.length > 0 ? sb.glyph : sb.label
            color: sb.toggled ? Colors.background : Colors.text
            font.family: sb.glyph.length > 0 ? "JetBrainsMono Nerd Font" : Qt.application.font.family
            font.pixelSize: sb.glyph.length > 0 ? 14 : 12
        }

        MouseArea {
            id: sbArea
            anchors.fill: parent
            enabled: sb.interactive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sb.triggered()
        }
    }
    readonly property string watermarkPath: {
        const configured = Directories.resolve(Config.sidebar.noNotifsImage);
        return configured.length > 0 ? configured : Directories.dinoImage;
    }

    radius: Motion.rounding.large
    color: Colors.layer

    ColumnLayout {
        id: column
        anchors { fill: parent; margins: 16 }
        spacing: 12

        // Header — clear-all moved to the footer row
        Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: Colors.text
            font.pixelSize: 15
            font.bold: true
        }

        // Body — the empty-state watermark and the history list share this area
        Item {
            id: body

            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state: watermark above the label. dino.png is black line art
            // on transparent, so it needs colourising, not just dimming
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.8
                spacing: 24

                opacity: root.isEmpty ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                }

                Image {
                    id: watermark

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    source: "file://" + root.watermarkPath
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: Math.round(body.width * 0.8)
                    asynchronous: true
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: Colors.outline }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No Notifications"
                    color: Colors.outline
                    font.pixelSize: 16
                }
            }

            // History list
            ListView {
                id: list
                anchors.fill: parent
                visible: !root.isEmpty
                interactive: contentHeight > height
                spacing: 8
                clip: true

                model: ScriptModel {
                    values: Notifs.appNameList
                }

                delegate: NotifGroupCard {
                    required property string modelData
                    appName: modelData
                    width: list.width
                }

                // Accumulated scroll target so rapid wheel ticks stack instead of each restarting the animation (comparison.md #37)
                property real scrollTargetY: 0

                Behavior on contentY {
                    NumberAnimation { id: scrollAnim; duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
                }

                onContentYChanged: if (!scrollAnim.running) list.scrollTargetY = list.contentY

                function scrollByDelta(delta: real): void {
                    const maxY = Math.max(0, list.contentHeight - list.height);
                    const base = scrollAnim.running ? list.scrollTargetY : list.contentY;
                    const targetY = Math.max(0, Math.min(base - delta, maxY));
                    list.scrollTargetY = targetY;
                    list.contentY = targetY;
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: event => {
                        if (list.contentHeight <= list.height) {
                            event.accepted = false;
                            return;
                        }
                        list.scrollByDelta(event.angleDelta.y / 2);
                    }
                }
            }
        }

        // Footer: DND toggle · count · clear all (end-4's statusRow)
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            StatusButton {
                Layout.preferredWidth: 46
                glyph: DndState.enabled ? "\uf1f6" : "\uf0f3" // bell-slash / bell
                toggled: DndState.enabled
                onTriggered: DndState.toggle()
            }

            StatusButton {
                Layout.fillWidth: true
                interactive: false
                label: root.isEmpty ? "No notifications" : `${Notifs.list.length} notification${Notifs.list.length === 1 ? "" : "s"}`
            }

            StatusButton {
                Layout.preferredWidth: 46
                glyph: "\uf1f8" // trash
                onTriggered: Notifs.clearAll()
            }
        }
    }
}
