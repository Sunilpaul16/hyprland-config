import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../services"
import "../../components"

// App group
Item {
    id: root

    required property string appName

    readonly property var group: Notifs.groupsByAppName[root.appName]
    readonly property list<var> notifs: root.group?.notifs ?? []
    readonly property int previewNum: Config.notifications.groupPreviewNum
    // Grouped once hiding
    readonly property bool grouped: root.notifs.length > root.previewNum
    readonly property int hiddenCount: root.notifs.length - root.previewNum
    readonly property bool expanded: Notifs.expandedApps.includes(root.appName)

    implicitHeight: column.implicitHeight

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: Motion.spacing.normal

        // Group header
        Rectangle {
            Layout.fillWidth: true
            visible: root.grouped
            implicitHeight: header.implicitHeight + 20
            radius: Motion.rounding.card
            color: Colors.layer
            border.width: root.group?.urgency === NotificationUrgency.Critical ? 1 : 0
            border.color: Colors.error

            RowLayout {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Motion.spacing.medium }
                spacing: Motion.spacing.normal

                // Representative icon
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: width / 2
                    color: root.group?.urgency === NotificationUrgency.Critical ? Colors.error : Colors.background
                    clip: true

                    Image {
                        anchors.fill: parent
                        visible: root.group?.image.length > 0
                        source: root.group?.image.length > 0 ? StringUtils.resolveNotifImage(root.group.image) : ""
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

                    StyledText {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        visible: root.group?.image.length === 0 && root.group?.appIcon.length === 0
                        text: "i"
                        color: root.group?.urgency === NotificationUrgency.Critical ? Colors.textOnError : Colors.primary
                        font.pixelSize: Motion.fontSize.label
                        font.bold: true
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.appName
                    font.pixelSize: Motion.fontSize.label
                    font.bold: true
                    elide: Text.ElideRight
                }

                StyledText {
                    text: root.group ? StringUtils.notifTime(root.group.time, Time.minutes) : ""
                    color: Colors.textMuted
                    font.pixelSize: Motion.fontSize.small
                }

                // Count badge
                Rectangle {
                    implicitWidth: countLabel.implicitWidth + 18
                    implicitHeight: countLabel.implicitHeight + 8
                    radius: height / 2
                    color: root.group?.urgency === NotificationUrgency.Critical ? Colors.error : Colors.background

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Motion.spacing.micro

                        StyledText {
                            id: countLabel
                            // Hidden count
                            text: root.expanded ? root.notifs.length : `+${root.hiddenCount}`
                            color: root.group?.urgency === NotificationUrgency.Critical ? Colors.textOnError : Colors.textMuted
                            font.pixelSize: Motion.fontSize.small
                        }

                        StyledText {
                            text: "⌄"
                            color: root.group?.urgency === NotificationUrgency.Critical ? Colors.textOnError : Colors.textMuted
                            font.pixelSize: Motion.fontSize.label
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

        // Member cards
        Repeater {
            model: ScriptModel {
                values: (!root.grouped || root.expanded) ? root.notifs : root.notifs.slice(0, root.previewNum)
            }

            NotifCard {
                Layout.fillWidth: true
            }
        }
    }
}
