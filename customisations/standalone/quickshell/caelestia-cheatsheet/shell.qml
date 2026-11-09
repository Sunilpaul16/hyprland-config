import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config

ShellRoot {
    id: root
    settings.watchFiles: false
    property bool opened: true
    property var groups: []
    property var palette: ({})
    property bool lightTheme: false
    readonly property var categoryIcons: ({
        Window: "web_asset", Workspace: "grid_view", App: "apps",
        Launcher: "rocket_launch", Screenshot: "photo_camera", Record: "videocam",
        System: "settings", Screen: "desktop_windows", Shell: "terminal",
        Help: "help", Touchpad: "touchpad_mouse", Kitty: "terminal"
    })
    function keyLabel(key) {
        const labels = {left: "←", right: "→", up: "↑", down: "↓",
            Print: "PrtSc", mouse_up: "Scroll ↑", mouse_down: "Scroll ↓",
            Minus: "−", Equal: "=", Space: "Space"};
        return labels[key] || key;
    }
    function packGroups(count) {
        const columns = Array.from({length: count}, () => []);
        const heights = Array(count).fill(0);
        const chunks = [];
        for (const group of groups) {
            for (let i = 0; i < group.rows.length; i += 8)
                chunks.push({title: group.title + (i ? " · continued" : ""), rows: group.rows.slice(i, i + 8)});
        }
        chunks.sort((a, b) => b.rows.length - a.rows.length);
        for (const group of chunks) {
            const index = heights.indexOf(Math.min(...heights));
            columns[index].push(group);
            heights[index] += 62 + group.rows.length * 44;
        }
        return columns;
    }
    onOpenedChanged: if (opened) resetScroll.restart()
    onGroupsChanged: resetScroll.restart()
    Timer { id: resetScroll; interval: 120; onTriggered: scroller.contentY = 0 }
    function colour(name, fallback) { return palette[name] ? "#" + palette[name] : fallback; }
    FileView {
        path: Qt.resolvedUrl("data.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.groups = JSON.parse(text())
    }
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { const scheme = JSON.parse(text()); root.palette = scheme.colours || {}; root.lightTheme = scheme.mode === "light"; }
    }
    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.opened = !root.opened; }
        function close(): void { root.opened = false; }
        function isOpen(): bool { return root.opened; }
    }
    FloatingWindow {
        id: win
        visible: root.opened
        title: "Shortcuts — Caelestia"
        implicitWidth: Math.min(screen.width - 64, 1320)
        implicitHeight: Math.min(screen.height - 64, 900)
        minimumSize.width: 600
        minimumSize.height: 400
        color: root.colour("surface", "#131317")
        surfaceFormat.opaque: false
        contentItem.Config.screen: screen.name
        contentItem.Tokens.screen: screen.name
        onVisibleChanged: if (!visible) root.opened = false
        Rectangle {
            id: panel
            anchors.fill: parent
            color: root.colour("surfaceContainerLow", "#1c1b1f")
            radius: Tokens.rounding.large
            MouseArea { anchors.fill: parent }
            FocusScope {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.opened = false
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 20
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "Your shortcuts"; color: root.colour("onSurface", "#e5e1e7"); font.family: "Rubik"; font.pixelSize: 28; font.bold: true }
                        }

                    }
                    Flickable {
                        id: scroller
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: cards.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}
                        Row {
                            id: cards
                            width: scroller.width - 12
                            spacing: 14
                            readonly property int columnCount: panel.width > 1100 ? 3 : panel.width > 700 ? 2 : 1
                            Repeater {
                                model: root.packGroups(cards.columnCount)
                                Column {
                                    id: categoryColumn
                                    required property var modelData
                                    width: (cards.width - cards.spacing * (cards.columnCount - 1)) / cards.columnCount
                                    spacing: 14
                                    Repeater {
                                        model: categoryColumn.modelData
                                        Rectangle {
                                            id: card
                                            required property var modelData
                                            width: categoryColumn.width
                                            height: cardContent.implicitHeight + 28
                                            radius: 16
                                            color: root.colour("surfaceContainerHigh", "#2a292e")
                                            Column {
                                                id: cardContent
                                                x: 14; y: 14
                                                width: parent.width - 28
                                                spacing: 12
                                                Row {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    spacing: 8
                                                    Text {
                                                        text: root.categoryIcons[card.modelData.title.split(" · ")[0]] || "keyboard"
                                                        font.family: "Material Symbols Rounded"
                                                        font.pixelSize: 22
                                                        color: root.colour("primary", "#c2c1ff")
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                    Text {
                                                        text: card.modelData.title
                                                        color: root.colour("primary", "#c2c1ff")
                                                        font.pixelSize: 16; font.bold: true
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                                Rectangle {
                                                    width: parent.width; height: 1
                                                    color: root.colour("outlineVariant", "#47464f")
                                                    opacity: 0.6
                                                }
                                                Column {
                                                    width: parent.width
                                                    spacing: 8
                                                    Repeater {
                                                        model: card.modelData.rows
                                                        RowLayout {
                                                            required property var modelData
                                                            width: parent.width
                                                            spacing: 12
                                                            Flow {
                                                                id: keyCombo
                                                                property string combo
                                                                combo: modelData.key
                                                                Layout.preferredWidth: parent.width * 0.54
                                                                Layout.fillWidth: false
                                                                Layout.alignment: Qt.AlignVCenter
                                                                spacing: 4
                                                                Repeater {
                                                                    model: keyCombo.combo.split(" + ")
                                                                    Row {
                                                                        required property string modelData
                                                                        required property int index
                                                                        spacing: 4
                                                                        Text {
                                                                            visible: parent.index > 0
                                                                            text: "+"
                                                                            anchors.verticalCenter: parent.verticalCenter
                                                                            color: root.colour("onSurfaceVariant", "#c8c5d1")
                                                                            font.pixelSize: 11
                                                                        }
                                                                        Rectangle {
                                                                            implicitWidth: Math.max(capText.implicitWidth + 12, 24)
                                                                            implicitHeight: capText.implicitHeight + 8
                                                                            radius: 5
                                                                            color: root.colour("surfaceContainer", "#201f23")
                                                                            border.width: 1
                                                                            border.color: root.colour("outline", "#918f9a")
                                                                            Text {
                                                                                id: capText
                                                                                anchors.centerIn: parent
                                                                                text: root.keyLabel(parent.parent.modelData)
                                                                                color: root.colour("onSurface", "#e5e1e7")
                                                                                font.family: "JetBrains Mono Nerd Font"
                                                                                font.pixelSize: 11
                                                                                font.bold: true
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            Text {
                                                                text: modelData.label
                                                                Layout.fillWidth: true
                                                                Layout.alignment: Qt.AlignVCenter
                                                                wrapMode: Text.Wrap
                                                                color: root.colour("onSurface", "#e5e1e7")
                                                                font.pixelSize: 12
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Item {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            width: closeGlyph.implicitWidth + Tokens.padding.extraSmall * 3
                            height: closeGlyph.implicitHeight + Tokens.padding.extraSmall * 2
                            z: 2
                            Accessible.role: Accessible.Button
                            Accessible.name: "Close cheatsheet"
                            Text {
                                id: closeGlyph
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 1
                                text: "close"
                                font: Tokens.font.icon.size(Tokens.font.icon.medium.pointSize).weight(Tokens.font.icon.medium.weight).vaxes(Tokens.font.icon.medium.variableAxes).fill("0.0").grade(root.lightTheme ? 0 : -25).build()
                                renderType: Text.QtRendering
                                color: closeMouse.containsMouse ? root.colour("error", "#ffb4ab") : root.colour("onSurfaceVariant", "#c8c5d1")
                                scale: closeMouse.pressed ? 0.8 : 1
                                Behavior on scale { Anim {} }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Tokens.anim.durations.expressiveDefaultEffects
                                        easing: Tokens.anim.expressiveDefaultEffects
                                    }
                                }
                            }
                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.opened = false
                            }
                        }
        }
    }
}
