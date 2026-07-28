import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../components"

// Dropdown for option lists too long to cycle through (SelectPill's mode).
// The list is a PopupWindow rather than an Item inside the panel: a menu of
// any height would otherwise be clipped at the panel window's own bounds
Item {
    id: root

    // [{ value, label }]
    property var options: []
    property string current: ""
    property string placeholder: "—"
    // Ceiling for the pill; long device names elide rather than stretch the row
    property int maxPillWidth: 330

    signal selected(string v)

    readonly property int currentIndex: root.options.findIndex(o => o.value === root.current)
    readonly property string displayText: root.options[root.currentIndex]?.label ?? root.placeholder

    property bool menuOpen: false

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    function close(): void {
        root.menuOpen = false;
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

            Text {
                id: label

                // Constant ceiling, so a long device name elides instead of
                // stretching the row
                Layout.maximumWidth: root.maxPillWidth - 16 * 2 - 24
                text: root.displayText
                color: Colors.text
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

    // Menu
    Loader {
        active: root.menuOpen && root.options.length > 0

        sourceComponent: PopupWindow {
            visible: true

            anchor {
                window: root.QsWindow.window
                item: pill
                edges: Edges.Bottom
                gravity: Edges.Bottom
                margins.top: 6
            }

            color: "transparent"
            implicitWidth: Math.max(pill.width, menuColumn.implicitWidth + 2 * 2)
            implicitHeight: menuColumn.implicitHeight + 2 * 2

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Colors.surface
                border.width: 1
                border.color: Colors.outlineVariant

                ColumnLayout {
                    id: menuColumn

                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 0

                    Repeater {
                        model: root.options

                        Rectangle {
                            required property int index
                            required property var modelData

                            Layout.fillWidth: true
                            implicitWidth: itemLabel.implicitWidth + 16 * 2 + 26
                            implicitHeight: 36
                            radius: 12
                            color: modelData.value === root.current ? Colors.secondaryContainer : itemHover.containsMouse ? Colors.background : "transparent"

                            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    id: itemLabel

                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: Colors.text
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
