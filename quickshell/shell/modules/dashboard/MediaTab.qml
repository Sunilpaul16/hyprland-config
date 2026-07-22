import "."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../services"

// Media tab: full-page now-playing — cover art, draggable seek, transport controls
Item {
    id: root

    property bool playerMenuOpen: false

    implicitWidth: (Media.hasPlayer ? hasMediaRow.implicitWidth : emptyState.implicitWidth) + 64
    implicitHeight: (Media.hasPlayer ? hasMediaRow.implicitHeight : emptyState.implicitHeight) + 64

    function formatTime(seconds: real): string {
        if (!seconds || seconds < 0 || isNaN(seconds))
            return "0:00";
        const total = Math.floor(seconds);
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    // No-media empty state
    ColumnLayout {
        id: emptyState

        anchors.centerIn: parent
        visible: !Media.hasPlayer
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\u{266A}"
            color: Colors.textMuted
            font.pixelSize: 56
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Nothing playing"
            color: Colors.textMuted
            font.pixelSize: 18
        }
    }

    // Has-media content
    RowLayout {
        id: hasMediaRow

        anchors.centerIn: parent
        visible: Media.hasPlayer
        spacing: 32

        // Cover art
        CoverArt {
            size: Config.dashboardMediaCoverArtSize
        }

        // Info + seek + controls
        ColumnLayout {
            Layout.preferredWidth: 320
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: Media.title.length > 0 ? Media.title : "Unknown title"
                color: Colors.text
                font.pixelSize: 22
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: Media.artist.length > 0 ? Media.artist : "Unknown artist"
                color: Colors.textMuted
                font.pixelSize: 15
                elide: Text.ElideRight
            }

            Item { Layout.preferredHeight: 20 }

            // Draggable seek slider — writes straight to the MPRIS player
            // object Media.qml already exposes (Media.qml itself has no
            // seek/write API, and isn't being extended for it this session)
            Slider {
                id: seekSlider

                Layout.fillWidth: true

                from: 0
                to: 1
                value: Media.length > 0 ? Media.position / Media.length : 0
                enabled: Media.activePlayer?.canSeek ?? false

                onPressedChanged: {
                    if (pressed)
                        return;
                    const player = Media.activePlayer;
                    if (player && player.canSeek)
                        player.position = seekSlider.value * Media.length;
                    seekSlider.value = Qt.binding(() => Media.length > 0 ? Media.position / Media.length : 0);
                }

                background: Rectangle {
                    x: seekSlider.leftPadding
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    width: seekSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Colors.surface

                    Rectangle {
                        width: seekSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Colors.primary
                    }
                }

                handle: Rectangle {
                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitWidth: 14
                    implicitHeight: 14
                    radius: 7
                    color: seekSlider.pressed ? Colors.text : Colors.primary
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: -4

                Text {
                    text: root.formatTime(Media.position)
                    color: Colors.textMuted
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.formatTime(Media.length)
                    color: Colors.textMuted
                    font.pixelSize: 11
                }
            }

            Item { Layout.preferredHeight: 16 }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                ToggleIconButton {
                    iconName: "shuffle"
                    active: Media.shuffle
                    visible: Media.shuffleSupported
                    onClicked: Media.toggleShuffle()
                }

                TransportButton {
                    glyph: "\u{23EE}"
                    enabled: Media.canGoPrevious
                    onClicked: Media.previous()
                }

                TransportButton {
                    glyph: Media.isPlaying ? "\u{23F8}" : "\u{25B6}"
                    enabled: Media.canTogglePlaying
                    big: true
                    onClicked: Media.togglePlaying()
                }

                TransportButton {
                    glyph: "\u{23ED}"
                    enabled: Media.canGoNext
                    onClicked: Media.next()
                }

                ToggleIconButton {
                    iconName: Media.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                    active: Media.loopState !== MprisLoopState.None
                    visible: Media.loopSupported
                    onClicked: Media.cycleLoopState()
                }
            }
        }
    }

    // Click-outside catcher for the player-menu dropdown
    MouseArea {
        anchors.fill: parent
        visible: root.playerMenuOpen
        onClicked: root.playerMenuOpen = false
    }

    // Multi-player selector — only shown with >1 active MPRIS player
    Item {
        id: playerSelector

        visible: Media.hasMultiplePlayers
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 16
        implicitWidth: pill.implicitWidth
        implicitHeight: pill.implicitHeight

        Rectangle {
            id: pill

            implicitWidth: pillRow.implicitWidth + 20
            implicitHeight: pillRow.implicitHeight + 12
            radius: implicitHeight / 2
            color: root.playerMenuOpen ? Colors.surface : (pillHover.containsMouse ? Colors.surface : "transparent")
            border.width: 1
            border.color: Colors.outline

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

            RowLayout {
                id: pillRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: Media.hasManualPlayer ? (Media.activePlayer?.identity || Media.activePlayer?.dbusName || "Unknown") : "Auto"
                    color: Colors.text
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Text {
                    text: root.playerMenuOpen ? "expand_less" : "expand_more"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: Colors.textMuted
                }
            }

            MouseArea {
                id: pillHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.playerMenuOpen = !root.playerMenuOpen
            }
        }

        // Dropdown list
        Rectangle {
            id: dropdown

            visible: root.playerMenuOpen
            anchors.top: pill.bottom
            anchors.right: parent.right
            anchors.topMargin: 6
            implicitWidth: Math.max(pill.implicitWidth, list.implicitWidth + 12)
            implicitHeight: list.implicitHeight + 12
            radius: 12
            // Surface, not background — this sits on top of the dashboard
            // panel's own Colors.background, so it needs contrast against it
            color: Colors.surface
            border.width: 1
            border.color: Colors.outline

            Column {
                id: list
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 6
                spacing: 2

                PlayerMenuEntry {
                    label: "Auto"
                    selected: !Media.hasManualPlayer
                    onClicked: {
                        Media.clearPlayerOverride();
                        root.playerMenuOpen = false;
                    }
                }

                Repeater {
                    model: Media.players

                    PlayerMenuEntry {
                        required property var modelData

                        label: modelData.identity || modelData.dbusName || "Unknown"
                        selected: Media.hasManualPlayer && Media.activePlayer === modelData
                        onClicked: {
                            Media.selectPlayer(modelData);
                            root.playerMenuOpen = false;
                        }
                    }
                }
            }
        }
    }

    component PlayerMenuEntry: Rectangle {
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

    component TransportButton: Item {
        id: btn

        property string glyph: ""
        property bool big: false
        signal clicked()

        implicitWidth: icon.implicitWidth
        implicitHeight: icon.implicitHeight
        opacity: btn.enabled ? 1 : 0.35

        Text {
            id: icon
            text: btn.glyph
            color: area.containsMouse ? Colors.text : Colors.textMuted
            font.pixelSize: btn.big ? 26 : 18

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // Shuffle/loop toggle — active-fill pill, same treatment as sidebarRight's TogglePill
    component ToggleIconButton: Rectangle {
        id: toggleBtn

        required property string iconName
        property bool active: false
        signal clicked()

        implicitWidth: icon.implicitWidth + 14
        implicitHeight: icon.implicitHeight + 14
        radius: implicitHeight / 2
        color: toggleBtn.active ? Colors.primary : (area.containsMouse ? Colors.surface : "transparent")

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        Text {
            id: icon
            anchors.centerIn: parent
            text: toggleBtn.iconName
            font.family: "Material Symbols Rounded"
            font.pixelSize: 16
            color: toggleBtn.active ? Colors.background : Colors.textMuted

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleBtn.clicked()
        }
    }
}
