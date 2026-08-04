import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Setting row
Rectangle {
    id: root

    property bool first: false
    property bool last: false
    property string label
    property string subtext
    // Mock flag
    property bool live: false

    default property alias control: controlSlot.data

    readonly property int endRadius: Motion.rounding.large
    readonly property int innerRadius: Motion.rounding.tiny

    Layout.fillWidth: true
    implicitHeight: Math.max(layout.implicitHeight + 12 * 2, 56)

    topLeftRadius: root.first ? root.endRadius : root.innerRadius
    topRightRadius: root.first ? root.endRadius : root.innerRadius
    bottomLeftRadius: root.last ? root.endRadius : root.innerRadius
    bottomRightRadius: root.last ? root.endRadius : root.innerRadius

    color: Colors.layer

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: Motion.spacing.wide

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            StyledText {
                Layout.fillWidth: true
                text: root.label
                color: root.live ? Colors.text : Colors.error
                font.pixelSize: Motion.fontSize.title
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext.length > 0
                text: root.subtext
                color: root.live ? Colors.outline : Qt.alpha(Colors.error, 0.65)
                font.pixelSize: Motion.fontSize.body
                elide: Text.ElideRight
            }
        }

        Item {
            id: controlSlot

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
