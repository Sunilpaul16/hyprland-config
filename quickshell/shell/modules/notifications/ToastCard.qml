import QtQuick
import "../../services"
import "../../components"

// Notification toast card
Rectangle {
    id: card

    required property Notif modelData

    implicitHeight: content.implicitHeight + 20
    radius: Motion.rounding.card
    // Floats over arbitrary windows
    color: Colors.layerOpaque
    border.width: modelData.critical ? 1 : 0
    border.color: Colors.error

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    // Slide-in entrance
    x: width
    Component.onCompleted: {
        x = 0;
        modelData.lock(card);
    }
    Component.onDestruction: {
        modelData.unlock(card);
        // Destroying a HoverHandler emits nothing
        modelData.hovered = false;
    }

    // Off while dragging
    Behavior on x {
        enabled: !swipeArea.drag.active
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    // Hover state
    HoverHandler {
        onHoveredChanged: card.modelData.hovered = hovered
    }

    // Click or swipe
    MouseArea {
        id: swipeArea
        anchors.fill: parent
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        preventStealing: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        drag.target: card
        drag.axis: Drag.XAxis

        onReleased: {
            if (Math.abs(card.x) < card.width * Config.notifications.swipeThreshold)
                card.x = 0;
            else
                card.modelData.popup = false;
        }
        // Suppressed on drag
        onClicked: mouse => {
            if (mouse.button !== Qt.MiddleButton)
                card.modelData.activate();
            card.modelData.popup = false;
        }
    }

    // Content
    Item {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Motion.spacing.medium }
        implicitHeight: Math.max(iconSlot.height, textCol.implicitHeight)

        // Constant, or it loops
        readonly property int chevronReserve: 24

        // Icon
        NotifIcon {
            id: iconSlot
            notif: card.modelData
            anchors.left: parent.left
            anchors.top: parent.top
        }

        // Text column
        Column {
            id: textCol
            anchors.left: iconSlot.right
            anchors.right: parent.right
            anchors.rightMargin: content.chevronReserve
            anchors.leftMargin: Motion.spacing.normal
            spacing: Motion.spacing.micro

            Row {
                width: parent.width
                spacing: Motion.spacing.small

                StyledText {
                    id: summaryText
                    visible: card.modelData.summary.length > 0
                    text: card.modelData.summary
                    font.pixelSize: Motion.fontSize.label
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width - appNameText.implicitWidth - parent.spacing
                }

                StyledText {
                    id: appNameText
                    visible: card.modelData.appName.length > 0
                    text: card.modelData.appName
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.small
                }
            }

            StyledText {
                id: bodyText
                width: parent.width
                visible: card.modelData.body.length > 0
                text: card.modelData.body
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.body
                // No link handler
                textFormat: card.modelData.bodyHasMarkup ? Text.StyledText : card.modelData.bodyHasMarkdown ? Text.MarkdownText : Text.PlainText
                wrapMode: card.modelData.expanded ? Text.WordWrap : Text.NoWrap
                elide: Text.ElideRight
                maximumLineCount: card.modelData.expanded ? 8 : 1
            }
        }

        // Expand/collapse toggle
        Item {
            id: chevron
            anchors.right: parent.right
            anchors.top: parent.top
            width: 18
            height: 18
            visible: bodyText.visible && (bodyText.truncated || card.modelData.expanded)

            StyledText {
                anchors.centerIn: parent
                text: "⌄" // chevron down
                color: chevronArea.containsMouse ? Colors.text : Colors.textMuted
                font.pixelSize: Motion.fontSize.label
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
