import "."
import QtQuick
import QtQuick.Layouts
import "../../../services"

// Storage usage ring + used/total for the selected physical disk —
// multiple mounts on one disk are merged by Storage.qml, not shown as
// separate partitions. Auto-hides when no disks are found, same pattern as
// BatteryCard/GpuCard. A disk selector (pill + dropdown, adapted from
// MediaTab.qml's player selector) appears once there's more than one disk.
Rectangle {
    id: root

    property bool diskMenuOpen: false

    readonly property var disk: Storage.selectedDisk
    readonly property bool hasDisk: disk !== null

    visible: hasDisk
    implicitWidth: hasDisk ? 260 : 0
    implicitHeight: hasDisk ? 140 : 0

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Component.onCompleted: Storage.ref()
    Component.onDestruction: Storage.unref()

    // Plain KiB -> MiB/GiB scaling helper, same shape as MemoryCard.qml's
    function formatKib(kib: real): string {
        if (!isFinite(kib) || kib < 0)
            return "0 KiB";
        if (kib >= 1024 * 1024)
            return (kib / (1024 * 1024)).toFixed(1) + " GiB";
        if (kib >= 1024)
            return (kib / 1024).toFixed(1) + " MiB";
        return Math.round(kib) + " KiB";
    }

    // Click-outside catcher for the disk-menu dropdown
    MouseArea {
        anchors.fill: parent
        visible: root.diskMenuOpen
        onClicked: root.diskMenuOpen = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14
        visible: root.hasDisk

        UsageRing {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            value: root.disk?.percentage ?? 0
            ringColor: Colors.primary

            Text {
                anchors.centerIn: parent
                text: Math.round((root.disk?.percentage ?? 0) * 100) + "%"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Storage"
                color: Colors.text
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.disk ? root.formatKib(root.disk.usedKib) + " / " + root.formatKib(root.disk.totalKib) : ""
                color: Colors.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    // Multi-disk selector — only shown with >1 disk found
    Item {
        id: diskSelector

        visible: Storage.disks.length > 1
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        implicitWidth: pill.implicitWidth
        implicitHeight: pill.implicitHeight

        Rectangle {
            id: pill

            implicitWidth: pillRow.implicitWidth + 14
            implicitHeight: pillRow.implicitHeight + 8
            radius: implicitHeight / 2
            color: root.diskMenuOpen ? Colors.background : (pillHover.containsMouse ? Colors.background : "transparent")
            border.width: 1
            border.color: Colors.outline

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

            RowLayout {
                id: pillRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.maximumWidth: 70
                    text: Storage.hasManualDisk ? Storage.selectedDisk.name : "Auto"
                    color: Colors.text
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                Text {
                    text: root.diskMenuOpen ? "\u{25B4}" : "\u{25BE}"
                    color: Colors.textMuted
                    font.pixelSize: 9
                }
            }

            MouseArea {
                id: pillHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.diskMenuOpen = !root.diskMenuOpen
            }
        }

        // Dropdown list
        Rectangle {
            id: dropdown

            visible: root.diskMenuOpen
            anchors.top: pill.bottom
            anchors.right: parent.right
            anchors.topMargin: 6
            implicitWidth: Math.max(pill.implicitWidth, list.implicitWidth + 12)
            implicitHeight: list.implicitHeight + 12
            radius: 12
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            Column {
                id: list
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 6
                spacing: 2

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

    component DiskMenuEntry: Rectangle {
        id: entry

        required property string label
        property bool selected: false
        signal clicked()

        implicitWidth: entryRow.implicitWidth + 20
        implicitHeight: entryRow.implicitHeight + 10
        radius: 6
        color: entryHover.containsMouse ? Colors.surface : "transparent"

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        RowLayout {
            id: entryRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: entry.selected ? "\u{25CF}" : ""
                color: Colors.primary
                font.pixelSize: 9
                Layout.preferredWidth: 9
            }

            Text {
                Layout.fillWidth: true
                text: entry.label
                color: Colors.text
                font.pixelSize: 12
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
