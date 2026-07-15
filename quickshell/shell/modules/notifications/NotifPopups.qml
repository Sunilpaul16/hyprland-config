pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"


// Notification popup window
PanelWindow {
    id: root

    // Visibility state
    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor

    // Layout constants
    readonly property int cardWidth: 340
    readonly property int topGap: 60
    readonly property int sideGap: 10
    readonly property int cardSpacing: 8

    // Positioning
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Window setup
    color: "transparent"
    exclusiveZone: 0

    visible: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Click-through everywhere except the stack itself
    mask: Region {
        item: stack
    }

    // Popup stack container
    Item {
        id: stack

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.topGap
        anchors.rightMargin: root.sideGap

        width: root.cardWidth
        height: Math.min(list.contentHeight, root.height - root.topGap - root.sideGap)
        clip: true

        // Popup list
        ListView {
            id: list

            anchors.fill: parent
            interactive: contentHeight > height
            spacing: 0
            cacheBuffer: root.height

            model: ScriptModel {
                values: root.isFocusedScreen ? Notifs.popups.filter(n => !n.closed) : []
            }

            delegate: Wrapper {}

            move: Transition {
                NumberAnimation { property: "y"; duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
            }
            displaced: Transition {
                NumberAnimation { property: "y"; duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing }
            }
        }
    }

    // Per-notification wrapper (handles remove animation)
    component Wrapper: Item {
        id: wrapper

        required property Notif modelData
        required property int index

        property Notif notif
        onModelDataChanged: if (modelData) notif = modelData
        Component.onCompleted: if (modelData) notif = modelData

        property int idx
        onIndexChanged: if (index !== -1) idx = index

        implicitWidth: stack.width
        implicitHeight: card.implicitHeight + (idx === 0 ? 0 : root.cardSpacing)

        ListView.onRemove: removeAnim.start()

        // Remove animation
        SequentialAnimation {
            id: removeAnim

            PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: true }
            PropertyAction { target: wrapper; property: "enabled"; value: false }
            NumberAnimation {
                target: card
                property: "x"
                to: stack.width
                duration: Motion.deliberateDuration
                easing.type: Motion.deliberateEasing
            }
            NumberAnimation {
                target: wrapper
                property: "implicitHeight"
                to: 0
                duration: Motion.deliberateDuration
                easing.type: Motion.deliberateEasing
            }
            PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: false }
        }

        ToastCard {
            id: card

            modelData: wrapper.notif ?? wrapper.modelData
            width: stack.width
            anchors.top: parent.top
            anchors.topMargin: wrapper.idx === 0 ? 0 : root.cardSpacing
        }
    }
}
