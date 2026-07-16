import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../services"


// Notification card
Rectangle {
    id: card

    required property Notif modelData

    readonly property bool hasImage: modelData.image.length > 0
    readonly property bool hasAppIcon: modelData.appIcon.length > 0
    readonly property string timeStr: Qt.formatDateTime(modelData.time, "hh:mm")

    implicitHeight: content.implicitHeight + 20
    radius: 14
    color: Colors.surface
    border.width: modelData.critical ? 1 : 0
    border.color: Colors.error

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    // Slide-in entrance, hold a lock while mounted
    x: width
    Component.onCompleted: {
        x = 0;
        modelData.lock(card);
    }
    Component.onDestruction: modelData.unlock(card)

    Behavior on x {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    // Hover state
    HoverHandler {
        id: hover
        onHoveredChanged: card.modelData.hovered = hovered
    }

    // Click to invoke action (collapsed only — chevron handles expand)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                card.modelData.close();
                return;
            }
            if (card.modelData.expanded)
                return;
            const actions = card.modelData.actions;
            if (actions.length === 1)
                actions[0].invoke();
        }
    }

    // Content
    Item {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        implicitHeight: Math.max(iconSlot.height, appNameText.height + headerCol.implicitHeight)

        // Reserve room for chevron (always) + close button (expanded only)
        readonly property int actionsReserve: card.modelData.expanded ? 44 : 24

        // Icon
        Rectangle {
            id: iconSlot
            width: 26
            height: 26
            radius: 13
            color: card.modelData.critical ? Colors.error : Colors.background
            clip: true
            anchors.left: parent.left
            anchors.top: parent.top

            Image {
                anchors.fill: parent
                visible: card.hasImage
                source: card.hasImage ? Qt.resolvedUrl(card.modelData.image) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            IconImage {
                anchors.centerIn: parent
                width: 15
                height: 15
                visible: !card.hasImage && card.hasAppIcon
                asynchronous: true
                source: card.hasAppIcon ? Quickshell.iconPath(card.modelData.appIcon, "dialog-information") : ""
            }

            // Flat monochrome fallback glyph, not a colorful emoji
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                visible: !card.hasImage && !card.hasAppIcon
                text: "i"
                color: card.modelData.critical ? Colors.textOnError : Colors.primary
                font.pixelSize: 13
                font.bold: true
            }
        }

        // App name (expanded only)
        Text {
            id: appNameText
            anchors.left: iconSlot.right
            anchors.right: parent.right
            anchors.rightMargin: content.actionsReserve
            anchors.top: parent.top
            anchors.leftMargin: 8
            visible: card.modelData.expanded && card.modelData.appName.length > 0
            height: visible ? implicitHeight : 0
            text: card.modelData.appName
            color: Colors.textMuted
            font.pixelSize: 10
            elide: Text.ElideRight
        }

        // Header column (summary, body, actions)
        Column {
            id: headerCol
            anchors.left: iconSlot.right
            anchors.right: parent.right
            anchors.rightMargin: content.actionsReserve
            anchors.top: appNameText.bottom
            anchors.leftMargin: 8
            spacing: 2

            // Summary · time
            Row {
                width: parent.width
                spacing: 6

                Text {
                    id: summaryText
                    visible: card.modelData.summary.length > 0
                    text: card.modelData.summary
                    color: Colors.text
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width - sepText.implicitWidth - timeText.implicitWidth - parent.spacing * 2
                }

                Text {
                    id: sepText
                    visible: card.modelData.summary.length > 0
                    text: "·"
                    color: Colors.textMuted
                    font.pixelSize: 12
                }

                Text {
                    id: timeText
                    text: card.timeStr
                    color: Colors.textMuted
                    font.pixelSize: 11
                }
            }

            // Body: one-line preview collapsed, full wrapped expanded
            Text {
                width: parent.width
                visible: card.modelData.body.length > 0
                text: card.modelData.body
                color: Colors.textMuted
                font.pixelSize: 12
                textFormat: Text.PlainText
                wrapMode: card.modelData.expanded ? Text.WordWrap : Text.NoWrap
                elide: Text.ElideRight
                maximumLineCount: card.modelData.expanded ? 8 : 1
            }

            // Action buttons (expanded only)
            Row {
                width: parent.width
                spacing: 8
                visible: card.modelData.expanded && card.modelData.actions.length > 0

                Repeater {
                    model: card.modelData.actions

                    Rectangle {
                        required property var modelData

                        readonly property int count: card.modelData.actions.length
                        width: (headerCol.width - (count - 1) * 8) / count
                        height: 28
                        radius: 8
                        color: btnArea.containsMouse ? Colors.outline : Colors.background

                        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            text: parent.modelData.text
                            color: Colors.text
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }

        // Close button (expanded only)
        Rectangle {
            id: closeBtn
            anchors.right: chevron.left
            anchors.top: parent.top
            anchors.rightMargin: 2
            width: 16
            height: 16
            radius: 8
            visible: card.modelData.expanded
            color: closeArea.containsMouse ? Colors.outline : "transparent"

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

            Text {
                anchors.centerIn: parent
                text: "✕" // ✕
                color: Colors.textMuted
                font.pixelSize: 10
            }

            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.modelData.close()
            }
        }

        // Expand/collapse toggle
        Item {
            id: chevron
            anchors.right: parent.right
            anchors.top: parent.top
            width: 18
            height: 18

            Text {
                anchors.centerIn: parent
                text: "⌄" // chevron down
                color: chevronArea.containsMouse ? Colors.text : Colors.textMuted
                font.pixelSize: 13
                rotation: card.modelData.expanded ? 180 : 0

                Behavior on rotation { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
            }

            MouseArea {
                id: chevronArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.modelData.expanded = !card.modelData.expanded
            }
        }
    }
}
