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

    // Preserve room for readable labels before moving controls below them.
    readonly property bool stacked: width < 640
        || controlSlot.implicitWidth + 240 + Motion.spacing.wide + 36 > width

    readonly property int endRadius: Motion.rounding.large
    readonly property int innerRadius: Motion.rounding.tiny

    Layout.fillWidth: true
    implicitHeight: Math.max(layout.implicitHeight + 12 * 2, 56)

    topLeftRadius: root.first ? root.endRadius : root.innerRadius
    topRightRadius: root.first ? root.endRadius : root.innerRadius
    bottomLeftRadius: root.last ? root.endRadius : root.innerRadius
    bottomRightRadius: root.last ? root.endRadius : root.innerRadius

    color: Colors.layer

    GridLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        columns: root.stacked ? 1 : 2
        columnSpacing: Motion.spacing.wide
        rowSpacing: Motion.spacing.normal

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: root.stacked ? 0 : 240
            Layout.preferredWidth: root.stacked ? layout.width
                : Math.max(240, layout.width
                    - Math.min(controlSlot.implicitWidth, layout.width * 0.5)
                    - layout.columnSpacing)
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            StyledText {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.label
                color: root.live ? Colors.text : Colors.error
                font.pixelSize: Motion.fontSize.title
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                visible: root.subtext.length > 0
                text: root.subtext
                color: root.live ? Colors.outline : Qt.alpha(Colors.error, 0.65)
                font.pixelSize: Motion.fontSize.body
                wrapMode: Text.Wrap
            }
        }

        RowLayout {
            id: controlSlot

            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillWidth: root.stacked
            Layout.minimumWidth: 0
            Layout.preferredWidth: root.stacked ? layout.width
                : Math.min(implicitWidth, layout.width * 0.5)
            Layout.maximumWidth: root.stacked ? layout.width
                : Math.max(0, layout.width - 240 - layout.columnSpacing)
            spacing: Motion.spacing.normal
        }
    }
}
