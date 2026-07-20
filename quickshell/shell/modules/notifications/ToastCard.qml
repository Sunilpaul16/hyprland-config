import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../services"

// Notification toast card
Rectangle {
    id: card

    required property Notif modelData

    readonly property bool hasImage: modelData.image.length > 0
    readonly property bool hasAppIcon: modelData.appIcon.length > 0

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
        onHoveredChanged: card.modelData.hovered = hovered
    }

    // Click anywhere to dismiss immediately
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.modelData.close()
    }

    // Content
    Item {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        implicitHeight: Math.max(iconSlot.height, textCol.implicitHeight)

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

        // Summary + app name + body column
        Column {
            id: textCol
            anchors.left: iconSlot.right
            anchors.right: parent.right
            anchors.leftMargin: 8
            spacing: 2

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
                    width: parent.width - appNameText.implicitWidth - parent.spacing
                }

                Text {
                    id: appNameText
                    visible: card.modelData.appName.length > 0
                    text: card.modelData.appName
                    color: Colors.textMuted
                    font.pixelSize: 11
                }
            }

            Text {
                width: parent.width
                visible: card.modelData.body.length > 0
                text: card.modelData.body
                color: Colors.textMuted
                font.pixelSize: 12
                textFormat: card.modelData.bodyHasMarkdown ? Text.MarkdownText : Text.PlainText
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
}
