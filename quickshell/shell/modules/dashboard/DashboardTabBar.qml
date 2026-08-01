import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Dashboard tab bar: icon/label buttons, stretchy underline, divider.
// Selection is raised rather than written — the panel owns currentTab
Item {
    id: root

    required property var model
    property int currentIndex: 0

    signal tabSelected(index: int)

    // Breathing room the hover fill expands into, above and
    // below the icon/label stack
    readonly property int indicatorSpacing: 5

    Layout.fillWidth: true
    implicitHeight: buttonsRow.implicitHeight + root.indicatorSpacing * 2 + activeIndicator.height + separator.height

    RowLayout {
        id: buttonsRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.indicatorSpacing
        spacing: 0

        Repeater {
            id: tabRepeater

            model: root.model

            delegate: Item {
                id: tabButton

                required property int index
                required property var modelData
                readonly property bool current: index === root.currentIndex
                // The underline hugs the label, not the whole slot
                readonly property real indicatorWidth: Math.max(tabIcon.implicitWidth, tabLabel.implicitWidth)

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: tabIcon.implicitHeight + tabLabel.implicitHeight

                // Hover fill
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height + root.indicatorSpacing * 2
                    radius: Motion.rounding.normal
                    color: tabHover.containsMouse ? Colors.layer : "transparent"

                    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
                }

                MaterialIcon {
                    id: tabIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: tabLabel.top
                    text: tabButton.modelData.iconName
                    color: tabButton.current ? Colors.primary : Colors.textMuted
                    font.pixelSize: 22
                    fill: tabButton.current ? 1 : 0

                    Behavior on fill { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
                }

                StyledText {
                    id: tabLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: tabButton.modelData.text
                    color: tabButton.current ? Colors.primary : Colors.textMuted
                    font.pixelSize: 13
                }

                MouseArea {
                    id: tabHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tabSelected(tabButton.index)
                }
            }
        }
    }

    // Stretchy active-tab underline (comparison.md #39)
    Rectangle {
        id: activeIndicator

        // itemAt(), not children[] — RowLayout reorders buttonsRow.children; tabRepeater.count is read only to force re-evaluation once the Repeater populates
        readonly property Item targetItem: {
            tabRepeater.count;
            return tabRepeater.itemAt(root.currentIndex);
        }

        anchors.top: buttonsRow.bottom
        anchors.topMargin: root.indicatorSpacing
        height: 3
        // Flat-bottomed: it sits directly on the divider below
        topLeftRadius: height
        topRightRadius: height
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Colors.primary

        AnimatedTabIndexPair {
            id: leftBound
            index: activeIndicator.targetItem ? activeIndicator.targetItem.x + (activeIndicator.targetItem.width - activeIndicator.targetItem.indicatorWidth) / 2 : 0
        }
        AnimatedTabIndexPair {
            id: rightBound
            index: activeIndicator.targetItem ? activeIndicator.targetItem.x + (activeIndicator.targetItem.width + activeIndicator.targetItem.indicatorWidth) / 2 : 0
        }

        x: Math.min(leftBound.idx1, leftBound.idx2)
        width: Math.max(rightBound.idx1, rightBound.idx2) - x
    }

    // Divider closing off the bar
    Rectangle {
        id: separator
        anchors.top: activeIndicator.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.outlineVariant
    }

    // Wheel-to-switch-tab
    MouseArea {
        z: 2
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (event.angleDelta.y < 0)
                root.tabSelected(Math.min(root.currentIndex + 1, root.model.length - 1));
            else
                root.tabSelected(Math.max(root.currentIndex - 1, 0));
        }
    }

    // idx1 (fast) and idx2 (slow) — min/max of both stretches the indicator instead of sliding it
    component AnimatedTabIndexPair: QtObject {
        required property real index

        property real idx1: index
        property real idx2: index

        Behavior on idx1 { NumberAnimation { duration: 100; easing.type: Easing.OutSine } }
        Behavior on idx2 { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }
    }
}
