import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"

// Dropdown for option lists too long to cycle through (SelectPill's mode).
// The list reparents onto the settings card rather than living in its own
// PopupWindow (caelestia's components/controls/Menu.qml does the same): that
// clears the page's clipping without a second Wayland surface, keeps the menu
// inside the panel, and avoids PopupAnchor, whose window property segfaults
Item {
    id: root

    // [{ value, label }]
    property var options: []
    property string current: ""
    property string placeholder: "—"
    // Ceiling for the pill; long device names elide rather than stretch the row
    property int maxPillWidth: 330

    // Menu height ceiling, in rows. Past this the list scrolls — a popup is a
    // separate surface, so an uncapped one renders outside the panel entirely
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

    // Found by walking up rather than threaded through every page
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

        // Sized from the layout's own natural width, never from pill.width --
        // measuring an eliding label against the container it sizes is the
        // loop CLAUDE.md warns about, and here it just collapsed the pill
        implicitWidth: pillLayout.implicitWidth + 16 * 2
        implicitHeight: 34
        radius: height / 2

        color: root.menuOpen || hover.containsMouse ? Colors.secondaryContainer : Colors.background

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        RowLayout {
            id: pillLayout

            anchors.centerIn: parent
            spacing: 6

            StyledText {
                id: label

                // Constant ceiling, so a long device name elides instead of
                // stretching the row
                Layout.maximumWidth: root.maxPillWidth - 16 * 2 - 24
                text: root.displayText
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            MaterialIcon {
                id: chevron

                text: "expand_more"
                color: Colors.outline
                font.pixelSize: 18
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

    // Menu. A child of the card, not a popup surface, so it draws above the
    // page and doubles as its own click-outside catcher
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

        // mapToItem is not reactive, so the bindings below read this to be
        // recomputed whenever an ancestor moves -- notably on page scroll
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
            // Flips above the pill when the menu would overrun the card
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

            // Absorbs clicks and wheel so they do not reach the catcher behind
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onWheel: e => e.accepted = true
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 2
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
                                anchors.leftMargin: 16
                                anchors.rightMargin: 10
                                spacing: 8

                                StyledText {
                                    id: itemLabel

                                    Layout.fillWidth: true
                                    text: modelData.label
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }

                                MaterialIcon {
                                    visible: modelData.value === root.current
                                    text: "check"
                                    color: Colors.primary
                                    font.pixelSize: 16
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
