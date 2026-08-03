import QtQuick
import QtQuick.Layouts
import "../../../components"
import "../../../services"

// Storage card
Rectangle {
    id: root

    property bool diskMenuOpen: false

    readonly property color accent: Colors.secondary
    readonly property var disk: Storage.selectedDisk
    readonly property bool hasDisk: disk !== null

    radius: Motion.rounding.hero
    color: Colors.layer

    implicitWidth: layout.implicitWidth + 40
    implicitHeight: layout.implicitHeight + 32

    Component.onCompleted: Storage.ref()
    Component.onDestruction: Storage.unref()

    // KiB scaling
    function formatKib(kib: real): string {
        if (!isFinite(kib) || kib < 0)
            return "0 KiB";
        if (kib >= 1024 * 1024)
            return (kib / (1024 * 1024)).toFixed(1) + " GiB";
        if (kib >= 1024)
            return (kib / 1024).toFixed(1) + " MiB";
        return Math.round(kib) + " KiB";
    }

    // Click-outside catcher
    MouseArea {
        anchors.fill: parent
        visible: root.diskMenuOpen
        onClicked: root.diskMenuOpen = false
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Motion.spacing.medium

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Motion.spacing.xlarge

            CircularProgress {
                implicitSize: usageColumn.implicitHeight + thickness + 24
                startAngle: -225
                sweepAngle: 270
                strokeWidth: 7
                value: root.disk?.percentage ?? 0
                fgColor: root.accent

                ColumnLayout {
                    id: usageColumn
                    anchors.centerIn: parent
                    spacing: -2

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hard_drive"
                        color: root.accent
                        font.pixelSize: 17
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round((root.disk?.percentage ?? 0) * 100) + "%"
                        color: root.accent
                        font.pixelSize: Motion.fontSize.xlarge
                        font.bold: true
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Used"
                        color: Colors.textMuted
                        font.pixelSize: Motion.fontSize.small
                    }
                }
            }

            ColumnLayout {
                spacing: Motion.spacing.micro

                StyledText {
                    text: "Storage"
                    font.pixelSize: Motion.fontSize.title
                    font.bold: true
                }

                StyledText {
                    text: root.hasDisk ? root.formatKib(root.disk.usedKib) + " / " + root.formatKib(root.disk.totalKib) : "No disks detected"
                    color: root.accent
                    font.pixelSize: Motion.fontSize.label
                }
            }
        }

        // Disk selector
        Item {
            id: diskSelector

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: pill.implicitWidth
            implicitHeight: pill.implicitHeight

            Rectangle {
                id: pill

                implicitWidth: Math.max(pillRow.implicitWidth + 20, 150)
                implicitHeight: pillRow.implicitHeight + 12
                radius: implicitHeight / 2
                color: (root.diskMenuOpen || pillHover.containsMouse) ? Colors.panel : Colors.secondaryContainer

                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                RowLayout {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: Motion.spacing.small

                    MaterialIcon {
                        text: "storage"
                        color: Colors.text
                        font.pixelSize: Motion.fontSize.title
                    }

                    StyledText {
                        Layout.maximumWidth: 90
                        text: !root.hasDisk ? "No disks" : (Storage.hasManualDisk ? Storage.selectedDisk.name : (root.disk?.name ?? "Auto"))
                        font.pixelSize: Motion.fontSize.body
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: root.diskMenuOpen ? "\u{25B4}" : "\u{25BE}"
                        color: Colors.textMuted
                        font.pixelSize: Motion.fontSize.tiny
                    }
                }

                MouseArea {
                    id: pillHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: Storage.disks.length > 1
                    onClicked: root.diskMenuOpen = !root.diskMenuOpen
                }
            }

            // Opens upward
            Rectangle {
                id: dropdown

                visible: root.diskMenuOpen
                anchors.bottom: pill.top
                anchors.horizontalCenter: pill.horizontalCenter
                anchors.bottomMargin: Motion.spacing.small
                implicitWidth: Math.max(pill.implicitWidth, list.implicitWidth + 12)
                implicitHeight: list.implicitHeight + 12
                radius: Motion.rounding.normal
                color: Colors.background
                border.width: 1
                border.color: Colors.outlineVariant

                Column {
                    id: list
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Motion.spacing.small
                    spacing: Motion.spacing.micro

                    DiskMenuEntry {
                        label: "Auto"
                        selected: !Storage.hasManualDisk
                        onClicked: {
                            Storage.clearDiskOverride();
                            root.diskMenuOpen = false;
                        }
                    }

                    Repeater {
                        model: Storage.disks

                        DiskMenuEntry {
                            required property var modelData

                            label: modelData.name
                            selected: Storage.hasManualDisk && Storage.selectedDisk === modelData
                            onClicked: {
                                Storage.selectDisk(modelData);
                                root.diskMenuOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }

    component DiskMenuEntry: Rectangle {
        id: entry

        required property string label
        property bool selected: false
        signal clicked()

        implicitWidth: entryRow.implicitWidth + 20
        implicitHeight: entryRow.implicitHeight + 10
        radius: Motion.rounding.tiny
        color: entryHover.containsMouse ? Colors.layer : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        RowLayout {
            id: entryRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Motion.spacing.medium
            anchors.right: parent.right
            anchors.rightMargin: Motion.spacing.medium
            spacing: Motion.spacing.normal

            StyledText {
                text: entry.selected ? "\u{25CF}" : ""
                color: Colors.primary
                font.pixelSize: Motion.fontSize.micro
                Layout.preferredWidth: 9
            }

            StyledText {
                Layout.fillWidth: true
                text: entry.label
                font.pixelSize: Motion.fontSize.body
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: entryHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: entry.clicked()
        }
    }
}
