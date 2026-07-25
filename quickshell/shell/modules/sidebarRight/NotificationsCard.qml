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
    readonly property string watermarkPath: {
        const configured = Directories.resolve(Config.sidebarNoNotifsImage);
        return configured.length > 0 ? configured : Directories.dinoImage;
    }

    radius: 18
    color: Colors.surface

    ColumnLayout {
        id: column
        anchors { fill: parent; margins: 16 }
        spacing: 12

        // Header: title + clear-all
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Colors.text
                font.pixelSize: 15
                font.bold: true
            }

            Rectangle {
                visible: Notifs.list.length > 0
                radius: 8
                color: clearArea.containsMouse ? Colors.outline : Colors.background
                implicitWidth: clearText.implicitWidth + 20
                implicitHeight: clearText.implicitHeight + 12

                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: Colors.text
                    font.pixelSize: 12
                }

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearAll()
                }
            }
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
    }
}
