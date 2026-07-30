import QtQuick
import Quickshell
import "../../services"


// Notification card
Rectangle {
    id: card

    required property Notif modelData

    implicitHeight: content.implicitHeight + 20
    radius: Motion.rounding.card
    color: Colors.layer
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

    // Off while dragging, so the card tracks the cursor instead of lagging
    // behind it, but still springs back when a swipe falls short
    Behavior on x {
        enabled: !swipeArea.drag.active
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    // Hover state
    HoverHandler {
        id: hover
        onHoveredChanged: card.modelData.hovered = hovered
    }

    // Click to invoke action (collapsed only — chevron handles expand),
    // or swipe sideways to dismiss
    MouseArea {
        id: swipeArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor
        preventStealing: true

        drag.target: card
        drag.axis: Drag.XAxis

        onReleased: {
            if (Math.abs(card.x) < card.width * Config.notifications.swipeThreshold)
                card.x = 0;
            else
                card.modelData.close();
        }
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

        // Reserve room for chevron (always) + close/copy buttons (expanded only)
        readonly property int actionsReserve: card.modelData.expanded ? 64 : 24

        // Icon
        NotifIcon {
            id: iconSlot
            notif: card.modelData
            anchors.left: parent.left
            anchors.top: parent.top
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
                    text: card.modelData.timeStr
                    color: Colors.textMuted
                    font.pixelSize: 11
                }
            }

            // Body: one-line preview collapsed, full wrapped expanded
            Text {
                id: bodyText
                width: parent.width
                visible: card.modelData.body.length > 0
                text: card.modelData.body
                color: Colors.textMuted
                font.pixelSize: 12
                // Markup wins over markdown — a body with both is far more
                // likely HTML with a stray asterisk than the reverse
                textFormat: card.modelData.bodyHasMarkup ? Text.StyledText : card.modelData.bodyHasMarkdown ? Text.MarkdownText : Text.PlainText
                wrapMode: card.modelData.expanded ? Text.WordWrap : Text.NoWrap
                elide: Text.ElideRight
                maximumLineCount: card.modelData.expanded ? 8 : 1
                linkColor: Colors.primary

                onLinkActivated: link => Qt.openUrlExternally(link)

                // NoButton so link clicks still reach the Text underneath
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    cursorShape: bodyText.hoveredLink.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
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
                        radius: Motion.rounding.small
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

        // Copy body to clipboard (expanded only)
        Rectangle {
            id: copyBtn
            anchors.right: closeBtn.left
            anchors.top: parent.top
            anchors.rightMargin: 2
            width: 16
            height: 16
            radius: Motion.rounding.small
            visible: card.modelData.expanded && card.modelData.body.length > 0
            color: copyArea.containsMouse ? Colors.outline : "transparent"

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

            Text {
                anchors.centerIn: parent
                text: "⧉"
                color: Colors.textMuted
                font.pixelSize: 10
            }

            MouseArea {
                id: copyArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.clipboardText = card.modelData.body
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
            radius: Motion.rounding.small
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
