import Quickshell

Region {
    required property var win

    x: win.width - 20
    y: 0
    width: 20
    height: 20
    intersection: Intersection.Subtract
}
