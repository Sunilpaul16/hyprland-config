pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Right-side popup stack, one PanelWindow per monitor (see shell.qml) but only
// the focused monitor ever renders cards — same focused-only pattern as the
// launcher / volume OSD. Adapted from caelestia's modules/notifications; the
// window stays mapped whenever this is the focused screen (empty mask makes it
// click-through when there are no cards) so the last card can finish its exit
// animation instead of being cut off.
//
// The delegate is a wrapper that owns the ListView delayRemove animation: on
// removal it holds the item alive (delayRemove), slides the card off-screen and
// collapses the gap, THEN lets the ListView destroy it. That destruction is
// what finally unlocks the Notif (see Notif.qml / NotifCard.qml), so a card is
// never destroyed — and its Notification never torn down — mid-animation.
PanelWindow {
    id: root

    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor

    // Card width, gaps, and how far below the top the stack starts (the bar is
    // 40px of content + a 14px corner strip — clear both).
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
    // Stay mapped on every monitor; gate the *content* on focus below instead.
    // Driving `visible` straight off isFocusedScreen loops: unmapping nulls
    // `screen`, which recomputes isFocusedScreen. When not focused the model is
    // empty, so the stack collapses to 0-height and the mask goes empty —
    // invisible and click-through all the same.
    visible: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    // Passive: receives pointer clicks on the cards (via the mask) but never
    // takes keyboard focus.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only the card stack is interactive; the rest of the screen stays
    // click-through. When there are no cards the stack is 0-height, so the
    // region is empty and the whole overlay is transparent to input.
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

            // Only the focused monitor renders cards. .filter both scopes to
            // focus and converts the list<Notif> into the JS array ScriptModel
            // wants (popups already excludes closed; this just re-materializes).
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

        // Hold our own reference to the Notif. During the delayRemove exit
        // animation the delegate outlives its model row, so the ListView nulls
        // `modelData` (and drops `index` to -1) — but the Notif object itself is
        // still alive, kept by the lock. Capturing the last non-null modelData
        // and driving the card off that keeps its content valid through the
        // fade; without it every card binding throws "TypeError: … of null".
        property Notif notif
        onModelDataChanged: if (modelData) notif = modelData
        Component.onCompleted: if (modelData) notif = modelData

        // Freeze the last real index too, so the top-card (idx 0, no leading
        // gap) spacing doesn't jump when index goes to -1 on removal.
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

            // notif ?? modelData: notif covers the fade (modelData nulled),
            // modelData covers the first frame before notif is captured.
            modelData: wrapper.notif ?? wrapper.modelData
            width: stack.width
            anchors.top: parent.top
            anchors.topMargin: wrapper.idx === 0 ? 0 : root.cardSpacing
        }
    }
}
