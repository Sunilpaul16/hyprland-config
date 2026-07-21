import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../bar"

// Fake full-screen corner rounding on all four corners, plus a hot corner
// that toggles the right sidebar on the two right corners only — this shell
// has no left sidebar to map the other two to (comparison.md #30)
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: Item {
                id: root

                // Visual rounding radius — matches the bar's own corner size
                readonly property int roundingSize: 14
                // Interactive click-target size for the right corners — bigger than
                // the rounding wedge so the hot zone is actually easy to hit
                readonly property int hotZoneSize: 24
                // Debug aid — flip to true and restart qs to render the hot-zones as
                // solid rectangles so their extent can be seen (comparison.md #30's
                // `visualize` flag; this sandbox can't simulate mouse clicks/hover)
                readonly property bool visualize: false

                component CornerWindow: PanelWindow {
                    id: cornerWindow
                    required property string corner
                    required property bool anchorTop
                    required property bool anchorRight
                    property bool interactive: false

                    screen: panelLoader.modelData
                    anchors {
                        top: cornerWindow.anchorTop
                        bottom: !cornerWindow.anchorTop
                        left: !cornerWindow.anchorRight
                        right: cornerWindow.anchorRight
                    }
                    implicitWidth: cornerWindow.interactive ? root.hotZoneSize : root.roundingSize
                    implicitHeight: cornerWindow.interactive ? root.hotZoneSize : root.roundingSize
                    exclusiveZone: 0
                    color: "transparent"
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "quickshell-screen-corner"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                    // Decorative wedge — pinned to the actual physical corner even
                    // when the window itself is bigger (interactive corners)
                    Corner {
                        anchors {
                            top: cornerWindow.anchorTop ? parent.top : undefined
                            bottom: !cornerWindow.anchorTop ? parent.bottom : undefined
                            left: !cornerWindow.anchorRight ? parent.left : undefined
                            right: cornerWindow.anchorRight ? parent.right : undefined
                        }
                        size: root.roundingSize
                        corner: cornerWindow.corner
                    }

                    // Hot zone — right corners only
                    Loader {
                        active: cornerWindow.interactive
                        anchors.fill: parent

                        sourceComponent: MouseArea {
                            onPressed: SidebarRightState.toggle()

                            Rectangle {
                                anchors.fill: parent
                                color: Colors.primary
                                visible: root.visualize
                            }
                        }
                    }
                }

                CornerWindow { corner: "topLeft"; anchorTop: true; anchorRight: false }
                CornerWindow { corner: "topRight"; anchorTop: true; anchorRight: true; interactive: true }
                CornerWindow { corner: "bottomLeft"; anchorTop: false; anchorRight: false }
                CornerWindow { corner: "bottomRight"; anchorTop: false; anchorRight: true; interactive: true }
            }
        }
    }
}
