import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Preset picker
ScrollPage {
    id: root

    title: "Colour presets"
    isSubPage: true

    property string hoveredId: ""

    // Grid sizing
    readonly property int columnCount: 3
    readonly property int rowCount: Math.max(1, Math.ceil(Schemes.list.length / root.columnCount))
    readonly property int gridSpace: root.availableHeight - grid.y - Motion.spacing.section
    readonly property int cellHeight: Math.max(56, Math.floor((root.gridSpace - Motion.spacing.small * (root.rowCount - 1)) / root.rowCount))

    function titleCase(s: string): string {
        return s.replace(/(^|[\s-])\S/g, c => c.toUpperCase());
    }

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

    // Missing corpus
    StyledText {
        visible: !Schemes.available
        text: "No presets found in matugen/schemes."
        color: Colors.textMuted
        font.pixelSize: Motion.fontSize.label
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    GridLayout {
        id: grid

        Layout.fillWidth: true
        columns: root.columnCount
        columnSpacing: Motion.spacing.small
        rowSpacing: Motion.spacing.small

        Repeater {
            model: Schemes.list

            Rectangle {
                id: row

                required property var modelData

                readonly property bool active: row.modelData.id === Theme.source

                Layout.fillWidth: true
                implicitHeight: root.cellHeight
                radius: Motion.rounding.card
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
                    anchors.leftMargin: Motion.spacing.large
                    anchors.rightMargin: Motion.spacing.large
                    spacing: Motion.spacing.large

                    // Two-tone preview
                    Rectangle {
                        id: swatch

                        readonly property int size: Math.min(52, row.height - Motion.spacing.section)

                        implicitWidth: swatch.size
                        implicitHeight: swatch.size
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
                            text: root.titleCase(row.modelData.scheme)
                            font.pixelSize: Motion.fontSize.title
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.titleCase(row.modelData.flavour)
                            color: Colors.textMuted
                            font.pixelSize: Motion.fontSize.body
                            elide: Text.ElideRight
                        }
                    }

                    StyledText {
                        visible: row.active
                        text: "✓"
                        color: Colors.primary
                        font.pixelSize: Motion.fontSize.title
                    }
                }
            }
        }
    }
}
