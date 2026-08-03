import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"

// Dropdown menu
Item {
    id: root

    // [{ value, label }]
    property var options: []
    property string current: ""
    property string placeholder: "—"
    // Pill width ceiling
    property int maxPillWidth: 330

    // Menu height ceiling
    property int maxVisibleItems: 6
    readonly property int itemHeight: 36

    signal selected(string v)

    readonly property int currentIndex: root.options.findIndex(o => o.value === root.current)
    readonly property string displayText: root.options[root.currentIndex]?.label ?? root.placeholder

    property bool menuOpen: false

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    function close(): void {
        root.menuOpen = false;
    }

    // Walk up to card
    function menuSurface(): var {
        let p = root.parent;
        while (p) {
            if (p.isSettingsCard === true)
                return p;
            p = p.parent;
        }
        return null;
    }

    Rectangle {
        id: pill

        // Sized from layout
        implicitWidth: pillLayout.implicitWidth + 16 * 2
        implicitHeight: 34
        radius: height / 2

        color: root.menuOpen || hover.containsMouse ? Colors.secondaryContainer : Colors.background

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        RowLayout {
            id: pillLayout

            anchors.centerIn: parent
            spacing: Motion.spacing.small

            StyledText {
                id: label

                // Constant ceiling
                Layout.maximumWidth: root.maxPillWidth - 16 * 2 - 24
                text: root.displayText
                font.pixelSize: Motion.fontSize.subhead
                elide: Text.ElideRight
            }

            MaterialIcon {
                id: chevron

                text: "expand_more"
                color: Colors.outline
                font.pixelSize: Motion.fontSize.header
                rotation: root.menuOpen ? 180 : 0

                Behavior on rotation { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
            }
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuOpen = !root.menuOpen
        }
    }

    // Menu
    MouseArea {
        id: menuLayer

        parent: root.menuSurface()
        anchors.fill: parent

        enabled: root.menuOpen && root.options.length > 0
        hoverEnabled: enabled
        visible: opacity > 0
        opacity: menuLayer.enabled ? 1 : 0

        onClicked: root.close()

        Behavior on opacity { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        // Recompute on move
        TransformWatcher {
            id: watcher

            a: menuLayer.parent
            b: pill
        }

        Rectangle {
            id: menu

            readonly property real belowY: {
                watcher.transform;
                return pill.mapToItem(menuLayer, 0, pill.height + 6).y;
            }
            readonly property real aboveY: {
                watcher.transform;
                return pill.mapToItem(menuLayer, 0, 0).y - height - 6;
            }
            // Flip above pill
            readonly property bool flipped: belowY + height > menuLayer.height && aboveY >= 0

            x: {
                watcher.transform;
                const raw = pill.mapToItem(menuLayer, 0, 0).x;
                return Math.max(6, Math.min(raw, menuLayer.width - width - 6));
            }
            y: menu.flipped ? menu.aboveY : menu.belowY

            implicitWidth: Math.max(pill.width, menuColumn.implicitWidth + 2 * 2)
            implicitHeight: Math.min(menuColumn.implicitHeight, root.maxVisibleItems * root.itemHeight) + 2 * 2

            radius: Motion.rounding.card
            color: Colors.surface
            border.width: 1
            border.color: Colors.outlineVariant

            // Absorb clicks
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onWheel: e => e.accepted = true
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: Motion.spacing.micro
                contentHeight: menuColumn.implicitHeight
                interactive: contentHeight > height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: menuColumn

                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: root.options

                        Rectangle {
                            required property int index
                            required property var modelData

                            Layout.fillWidth: true
                            implicitWidth: itemLabel.implicitWidth + 16 * 2 + 26
                            implicitHeight: root.itemHeight
                            radius: Motion.rounding.normal
                            color: modelData.value === root.current ? Colors.secondaryContainer : itemHover.containsMouse ? Colors.background : "transparent"

                            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Motion.spacing.xlarge
                                anchors.rightMargin: Motion.spacing.medium
                                spacing: Motion.spacing.normal

                                StyledText {
                                    id: itemLabel

                                    Layout.fillWidth: true
                                    text: modelData.label
                                    font.pixelSize: Motion.fontSize.subhead
                                    elide: Text.ElideRight
                                }

                                MaterialIcon {
                                    visible: modelData.value === root.current
                                    text: "check"
                                    color: Colors.primary
                                    font.pixelSize: Motion.fontSize.large
                                }
                            }

                            MouseArea {
                                id: itemHover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selected(modelData.value);
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
