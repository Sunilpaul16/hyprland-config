import QtQuick
import "../"
import "../../../services"

// Crosshair widget
OverlayWidget {
    id: root

    readonly property var cfg: Config.overlay.crosshair
    readonly property int reach: root.cfg.gap + root.cfg.length + (root.cfg.outline ? 2 : 0)

    identifier: "crosshair"
    showBackground: false

    Item {
        id: cross
        width: root.reach * 2
        height: root.reach * 2
        opacity: root.cfg.opacity

        // Centre dot
        Rectangle {
            anchors.centerIn: parent
            width: root.cfg.dotSize + (root.cfg.outline ? 2 : 0)
            height: width
            visible: root.cfg.centerDot
            color: root.cfg.outline ? "#000000" : "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: root.cfg.dotSize
                height: width
                color: root.cfg.color
            }
        }

        CrosshairLine {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: root.cfg.gap
            thickness: root.cfg.thickness
            length: root.cfg.length
            outline: root.cfg.outline
            lineColor: root.cfg.color
        }

        CrosshairLine {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: root.cfg.gap
            thickness: root.cfg.thickness
            length: root.cfg.length
            outline: root.cfg.outline
            lineColor: root.cfg.color
        }

        CrosshairLine {
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.horizontalCenter
            anchors.rightMargin: root.cfg.gap
            thickness: root.cfg.thickness
            length: root.cfg.length
            outline: root.cfg.outline
            lineColor: root.cfg.color
        }

        CrosshairLine {
            horizontal: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: root.cfg.gap
            thickness: root.cfg.thickness
            length: root.cfg.length
            outline: root.cfg.outline
            lineColor: root.cfg.color
        }
    }
}
