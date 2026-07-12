pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland


PanelWindow {
    id: root

    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor


    readonly property int cardWidth: 360
    readonly property int topGap: 60
    readonly property int sideGap: 14
    readonly property int cardSpacing: 10

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusiveZone: 0

    visible: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: stack
    }

    Item {
        id: stack

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.topGap
        anchors.rightMargin: root.sideGap

        width: root.cardWidth
        height: Math.min(list.contentHeight, root.height - root.topGap - root.sideGap)
        clip: true

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
                NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
            }
            displaced: Transition {
                NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
            }
        }
    }

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

        SequentialAnimation {
            id: removeAnim

            PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: true }
            PropertyAction { target: wrapper; property: "enabled"; value: false }
            NumberAnimation {
                target: card
                property: "x"
                to: stack.width
                duration: 200
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: wrapper
                property: "implicitHeight"
                to: 0
                duration: 180
                easing.type: Easing.OutCubic
            }
            PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: false }
        }

        NotifCard {
            id: card

            modelData: wrapper.notif ?? wrapper.modelData
            width: stack.width
            anchors.top: parent.top
            anchors.topMargin: wrapper.idx === 0 ? 0 : root.cardSpacing
        }
    }
}
