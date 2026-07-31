import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// One row of a settings group — label (+ optional subtext) on the left, a
// control slotted on the right. `first`/`last` round off the ends of a run of
// rows so a stack of these reads as one card, with no container around them
Rectangle {
    id: root

    property bool first: false
    property bool last: false
    property string label
    property string subtext
    // Rows are mock until proven otherwise: a red label flags anything the
    // panel displays but doesn't actually read or drive. Set live: true once
    // the row is backed by something real
    property bool live: false

    default property alias control: controlSlot.data

    readonly property int endRadius: 18
    readonly property int innerRadius: 6

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
        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            StyledText {
                Layout.fillWidth: true
                text: root.label
                color: root.live ? Colors.text : Colors.error
                font.pixelSize: 15
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext.length > 0
                text: root.subtext
                color: root.live ? Colors.outline : Qt.alpha(Colors.error, 0.65)
                font.pixelSize: 12
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
