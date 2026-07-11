import QtQuick
import "../"

// A rounded pill background wrapping one piece of bar content, styled after
// end-4's BarGroup.qml.
//
// Aliases to `inner.data` (not `inner.children`) since `data` is the
// generic "reparent anything, visual or not" property — the standard QML
// idiom for "wrap arbitrary content" components. Named `content`, not
// `data`, because `Item` already has its own built-in `data` property
// (its default property) — reusing that name here would shadow it.
Item {
    id: root

    default property alias content: inner.data
    property int horizontalPadding: 10
    property int pillHeight: 32

    implicitWidth: inner.childrenRect.width + horizontalPadding * 2
    implicitHeight: pillHeight

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
