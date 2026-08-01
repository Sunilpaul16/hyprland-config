import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Nav pane row — icon chip + label/description, with corner radii encoding
// where it sits in its category run
Rectangle {
    id: root

    required property var page
    required property int pageIndex
    required property bool runStart
    required property bool runEnd

    readonly property bool current: SettingsState.currentPageIdx === root.pageIndex

    // Run ends round off, inner joints stay square, the selected row pops fully round and a press pulls it back in
    readonly property int endRadius: 18
    readonly property int innerRadius: 6
    readonly property int currentRadius: 22
    readonly property int pressRadius: Motion.rounding.normal

    property int topRadius: hover.pressed ? root.pressRadius : root.current ? root.currentRadius : root.runStart ? root.endRadius : root.innerRadius
    property int bottomRadius: hover.pressed ? root.pressRadius : root.current ? root.currentRadius : root.runEnd ? root.endRadius : root.innerRadius

    Behavior on topRadius { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
    Behavior on bottomRadius { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

    implicitHeight: layout.implicitHeight + 14 * 2

    topLeftRadius: root.topRadius
    topRightRadius: root.topRadius
    bottomLeftRadius: root.bottomRadius
    bottomRightRadius: root.bottomRadius

    color: root.current ? Colors.secondaryContainer : hover.containsMouse ? Colors.layer : Qt.alpha(Colors.layer, 0.55)

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        // Icon chip
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 38
            implicitHeight: 38
            radius: width / 2
            color: root.current ? Colors.primary : Colors.secondaryContainer

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

            MaterialIcon {
                anchors.centerIn: parent
                text: root.page.icon
                color: root.current ? Colors.background : Colors.text
                font.pixelSize: 20
                fill: root.current ? 1 : 0

                Behavior on fill { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
                Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.page.label
                font.pixelSize: 15
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.page.description
                color: Colors.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SettingsState.currentPageIdx = root.pageIndex
    }
}
