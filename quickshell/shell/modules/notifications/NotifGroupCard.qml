import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../services"

// Per-app notification group — a single NotifCard, or a collapsible header over the member cards (comparison.md #26)
Item {
    id: root

    required property string appName

    readonly property var group: Notifs.groupsByAppName[root.appName]
    readonly property list<var> notifs: root.group?.notifs ?? []
    readonly property bool grouped: root.notifs.length > 1
    readonly property bool expanded: Notifs.expandedApps.includes(root.appName)

    implicitHeight: column.implicitHeight

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 8

        // Group header — only shown once there's more than one notification to collapse
        Rectangle {
            Layout.fillWidth: true
            visible: root.grouped
            implicitHeight: header.implicitHeight + 20
            radius: 14
            color: Colors.surface
            border.width: root.group?.urgency === NotificationUrgency.Critical ? 1 : 0
            border.color: Colors.error

            RowLayout {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 8

                // Representative icon
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: root.group?.urgency === NotificationUrgency.Critical ? Colors.error : Colors.background
                    clip: true

                    Image {
                        anchors.fill: parent
                        visible: root.group?.image.length > 0
                        source: root.group?.image.length > 0 ? Qt.resolvedUrl(root.group.image) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }

                    IconImage {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        visible: root.group?.image.length === 0 && root.group?.appIcon.length > 0
                        asynchronous: true
                        source: root.group?.appIcon.length > 0 ? Quickshell.iconPath(root.group.appIcon, "dialog-information") : ""
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        visible: root.group?.image.length === 0 && root.group?.appIcon.length === 0
                        text: "i"
                        color: root.group?.urgency === NotificationUrgency.Critical ? Colors.textOnError : Colors.primary
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.appName
                    color: Colors.text
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    text: root.group ? Qt.formatDateTime(root.group.time, "hh:mm") : ""
                    color: Colors.textMuted
                    font.pixelSize: 11
                }

                // Count badge — toggles the group open/closed
                Rectangle {
                    implicitWidth: countLabel.implicitWidth + 18
                    implicitHeight: countLabel.implicitHeight + 8
                    radius: height / 2
                    color: root.group?.urgency === NotificationUrgency.Critical ? Colors.error : Colors.background

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            id: countLabel
                            text: root.notifs.length
                            color: root.group?.urgency === NotificationUrgency.Critical ? Colors.textOnError : Colors.textMuted
                            font.pixelSize: 11
                        }

                        Text {
                            text: "⌄"
                            color: root.group?.urgency === NotificationUrgency.Critical ? Colors.textOnError : Colors.textMuted
                            font.pixelSize: 13
                            rotation: root.expanded ? 180 : 0

                            Behavior on rotation { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.toggleAppExpand(root.appName)
                    }
                }
            }
        }

        // Member cards — always shown when ungrouped, else gated on expanded
        Repeater {
            model: ScriptModel {
                values: (!root.grouped || root.expanded) ? root.notifs : []
            }

            NotifCard {
                Layout.fillWidth: true
            }
        }
    }
}
