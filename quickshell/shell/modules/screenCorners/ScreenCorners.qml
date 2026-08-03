import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../components"

// Screen corners
Scope {
    Variants {
        model: Quickshell.screens

        PanelLoader {
            id: panelLoader
            required property var modelData

            component: Item {
                id: root

                // Rounding radius
                readonly property int roundingSize: 14
                // Hot zone size
                readonly property int hotZoneSize: 24
                // Debug aid
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
                    exclusionMode: ExclusionMode.Ignore
                    color: "transparent"
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "quickshell-screen-corner"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                    // Decorative wedge
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

                    // Hot zone
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
