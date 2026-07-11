import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// One notification popup card. Adapted from caelestia's Notification.qml but
// collapsed-only (no drag-to-expand/dismiss gestures, no progress ring, no
// markdown/link handling — those are a later chunk) and re-themed onto
// Colors.qml. Layout: app icon or image, app name + summary + body, an accent
// keyed to urgency (critical = Colors.error), optional action buttons.
//
// Lock lifecycle (see Notif.qml): lock on appear, unlock on destroy. This card
// is what keeps its Notif alive through the slide-out, so the Notification is
// never destroyed mid-animation.
Rectangle {
    id: card

    required property Notif modelData

    readonly property bool hasImage: modelData.image.length > 0
    readonly property bool hasAppIcon: modelData.appIcon.length > 0
    readonly property color accent: modelData.critical ? Colors.error : modelData.urgency === NotificationUrgency.Low ? Colors.outline : Colors.primary

    implicitHeight: layout.implicitHeight + 24
    radius: 14
    color: Colors.surface
    border.width: modelData.critical ? 1 : 0
    border.color: Colors.error

    // Slide in from the right on appear; lock immediately so the Notif can't be
    // torn down before this card is done animating. The slide-out on removal is
    // driven by the ListView wrapper (see NotifPopups.qml), which overrides this
    // Behavior for the duration of the exit animation.
    x: width
    Component.onCompleted: {
        x = 0;
        modelData.lock(card);
    }
    Component.onDestruction: modelData.unlock(card)

    Behavior on x {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Pause the auto-dismiss timer while hovered (Notif.timer reads this).
    HoverHandler {
        id: hover
        onHoveredChanged: card.modelData.hovered = hovered
    }

    // Urgency accent strip down the left edge.
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 6
        width: 3
        radius: width / 2
        color: card.accent
    }

    // Body click: if the notification has exactly one action, clicking the card
    // invokes it (caelestia's touch). Middle-click dismisses. Declared before
    // the buttons so their own MouseAreas sit on top and consume their clicks.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                card.modelData.close();
                return;
            }
            const actions = card.modelData.actions;
            if (actions.length === 1)
                actions[0].invoke();
        }
    }

    Column {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        anchors.topMargin: 12
        spacing: 8

        Row {
            width: parent.width
            spacing: 12

            // Icon slot: notification image if present, else the app icon, else
            // a bell fallback.
            Item {
                width: 44
                height: 44

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    clip: true
                    visible: card.hasImage
                    color: Colors.background

                    Image {
                        anchors.fill: parent
                        source: card.hasImage ? Qt.resolvedUrl(card.modelData.image) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }
                }

                IconImage {
                    anchors.fill: parent
                    visible: !card.hasImage && card.hasAppIcon
                    asynchronous: true
                    source: card.hasAppIcon ? Quickshell.iconPath(card.modelData.appIcon, "dialog-information") : ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !card.hasImage && !card.hasAppIcon
                    text: "\u{1F514}" // bell
                    font.pixelSize: 22
                }
            }

            // Text column takes the rest of the row width, minus the icon.
            Column {
                width: parent.width - 44 - parent.spacing
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    visible: card.modelData.appName.length > 0
                    text: card.modelData.appName
                    color: Colors.textMuted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    width: parent.width
                    visible: card.modelData.summary.length > 0
                    text: card.modelData.summary
                    color: Colors.text
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    width: parent.width
                    visible: card.modelData.body.length > 0
                    text: card.modelData.body
                    color: Colors.textMuted
                    font.pixelSize: 12
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 4
                }
            }
        }

        // Action buttons, if any. Invoking a (non-resident) action makes the
        // server close the notification, which flows back through Notif.close()
        // via onClosed — so no manual dismiss needed here.
        Row {
            width: parent.width
            spacing: 8
            visible: card.modelData.actions.length > 0

            Repeater {
                model: card.modelData.actions

                Rectangle {
                    required property var modelData

                    readonly property int count: card.modelData.actions.length
                    width: (layout.width - (count - 1) * 8) / count
                    height: 30
                    radius: 8
                    color: btnArea.containsMouse ? Colors.outline : Colors.background

                    Behavior on color { ColorAnimation { duration: 120 } }

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

    // Close (X) button, top-right, on top of the body MouseArea.
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        width: 20
        height: 20
        radius: width / 2
        color: closeArea.containsMouse ? Colors.outline : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "✕" // ✕
            color: Colors.textMuted
            font.pixelSize: 11
        }

        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.modelData.close()
        }
    }
}
