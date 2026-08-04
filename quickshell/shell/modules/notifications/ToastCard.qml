import QtQuick
import "../../services"
import "../../components"

// Notification toast card
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

        drag.target: card
        drag.axis: Drag.XAxis

        onReleased: {
            if (Math.abs(card.x) < card.width * Config.notifications.swipeThreshold)
                card.x = 0;
            else
                card.modelData.popup = false;
        }
        // Suppressed on drag
        onClicked: card.modelData.close()
    }

    // Content
    Item {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        implicitHeight: Math.max(iconSlot.height, textCol.implicitHeight)

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
                width: parent.width
                visible: card.modelData.body.length > 0
                text: card.modelData.body
                color: Colors.textMuted
                font.pixelSize: Motion.fontSize.body
                // No link handler
                textFormat: card.modelData.bodyHasMarkup ? Text.StyledText : card.modelData.bodyHasMarkdown ? Text.MarkdownText : Text.PlainText
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
}
