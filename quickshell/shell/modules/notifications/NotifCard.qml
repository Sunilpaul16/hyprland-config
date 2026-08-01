import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"


// Notification card
Rectangle {
    id: card

    required property Notif modelData

    // Pill used by the expanded card's close / action / copy row
    component CardButton: Rectangle {
        id: btn

        property string label: ""
        property string glyph: ""
        signal triggered

        implicitHeight: 32
        radius: Motion.rounding.normal
        color: btnArea.containsMouse ? Colors.outline : Colors.background

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        StyledText {
            anchors.centerIn: parent
            width: parent.width - 16
            text: btn.glyph.length > 0 ? btn.glyph : btn.label
            font.pixelSize: btn.glyph.length > 0 ? 13 : 12
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.triggered()
        }
    }

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

        // Reserve room for the chevron; close/copy now live in the button row
        readonly property int actionsReserve: 24

        // Icon
        NotifIcon {
            id: iconSlot
            notif: card.modelData
            anchors.left: parent.left
            anchors.top: parent.top
        }

        // App name (expanded only)
        StyledText {
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

                StyledText {
                    id: summaryText
                    visible: card.modelData.summary.length > 0
                    text: card.modelData.summary
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width - sepText.implicitWidth - timeText.implicitWidth - parent.spacing * 2
                }

                StyledText {
                    id: sepText
                    visible: card.modelData.summary.length > 0
                    text: "·"
                    color: Colors.textMuted
                    font.pixelSize: 12
                }

                StyledText {
                    id: timeText
                    text: card.modelData.timeStr
                    color: Colors.textMuted
                    font.pixelSize: 11
                }
            }

            // Body: one-line preview collapsed, full wrapped expanded
            StyledText {
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

            // Button row (expanded only): close, the app's own actions, copy — with no actions the two icons split the width
            Item {
                width: parent.width
                height: card.modelData.expanded ? 32 : 0
                visible: height > 0

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    CardButton {
                        Layout.fillWidth: true
                        glyph: "✕"
                        onTriggered: card.modelData.close()
                    }

                    Repeater {
                        model: card.modelData.actions

                        CardButton {
                            required property var modelData
                            Layout.fillWidth: true
                            label: modelData.text
                            onTriggered: modelData.invoke()
                        }
                    }

                    CardButton {
                        id: copyBtn
                        Layout.fillWidth: true
                        visible: card.modelData.body.length > 0
                        glyph: copiedTimer.running ? "✓" : "⧉"

                        onTriggered: {
                            Quickshell.clipboardText = card.modelData.body;
                            copiedTimer.restart();
                        }

                        // Brief tick as copy confirmation
                        Timer {
                            id: copiedTimer
                            interval: 1500
                        }
                    }
                }
            }
        }

        // Expand/collapse toggle
        Item {
            id: chevron
            anchors.right: parent.right
            anchors.top: parent.top
            width: 18
            height: 18

            StyledText {
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
