import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Static preset picker, reached from Wallpaper & style's Presets pill.
// Highlighting a row themes the shell with that preset without applying it
ScrollPage {
    id: root

    title: "Colour presets"
    isSubPage: true

    property string hoveredId: ""

    onHoveredIdChanged: {
        if (root.hoveredId)
            Schemes.loadPreset(root.hoveredId, Theme.mode === "light" ? "light" : "dark");
        else
            ColorsLoader.clearPreview();
    }

    Component.onDestruction: ColorsLoader.clearPreview()

    Connections {
        target: Schemes

        function onPresetLoaded(id: string): void {
            if (id === root.hoveredId)
                ColorsLoader.previewPalette(Schemes.colours);
        }
    }

    SectionLabel {
        text: "Presets"
    }

    // Only reachable if the vendored corpus is missing
    StyledText {
        visible: !Schemes.available
        text: "No presets found in matugen/schemes."
        color: Colors.textMuted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: Schemes.list

            Rectangle {
                id: row

                required property var modelData

                readonly property bool active: row.modelData.id === Theme.source

                Layout.fillWidth: true
                implicitHeight: 52
                radius: Motion.rounding.item
                color: rowArea.containsMouse ? Colors.layer : "transparent"

                MouseArea {
                    id: rowArea

                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: root.hoveredId = row.modelData.id
                    onExited: {
                        if (root.hoveredId === row.modelData.id)
                            root.hoveredId = "";
                    }
                    onClicked: {
                        root.hoveredId = "";
                        ColorsLoader.clearPreview();
                        Theme.applyPreset(row.modelData.id);
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // Two-tone preview in the preset's own colours: its surface
                    // as the disc, its primary filling the right half
                    Rectangle {
                        id: swatch

                        implicitWidth: 32
                        implicitHeight: 32
                        radius: width / 2
                        color: row.modelData.surface
                        border.width: 1
                        border.color: row.modelData.outline

                        Item {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width / 2
                            clip: true

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: swatch.width
                                implicitHeight: swatch.height
                                radius: width / 2
                                color: row.modelData.primary
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData.flavour
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData.scheme
                            color: Colors.textMuted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    StyledText {
                        visible: row.active
                        text: "✓"
                        color: Colors.primary
                        font.pixelSize: 15
                    }
                }
            }
        }
    }
}
