import QtQuick
import "../"

// Pill container
Item {
    id: root

    default property alias content: inner.data
    property int horizontalPadding: 10
    property int pillHeight: 32

    implicitWidth: inner.childrenRect.width + horizontalPadding * 2
    implicitHeight: pillHeight

    // Background
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.surface
    }

    Item {
        id: inner
        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
