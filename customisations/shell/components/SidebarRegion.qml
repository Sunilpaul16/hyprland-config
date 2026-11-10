import Quickshell

Region {
    required property var win

    property bool active: true

    x: win.width - width
    y: 0
    width: active ? 20 : 0
    height: active ? 20 : 0
    intersection: Intersection.Subtract
}
