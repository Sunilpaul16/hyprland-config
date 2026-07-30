import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Nav pane — search field above a scrolling, category-grouped page list
Item {
    id: root

    required property var pageModel
    property bool panelActive: false

    readonly property int searchHeight: 46
    readonly property int listTopMargin: 14
    readonly property int rowSpacing: 3
    readonly property int runGap: 12
    // Mirrors NavItem's implicitHeight (38px icon chip + 14 padding a side);
    // it can't be read off a delegate without instantiating one
    readonly property int rowHeight: 66

    // Height the unfiltered list wants, derived from the model rather than
    // from listColumn — the panel sizes itself off this, and reading a live
    // child that the panel's own width feeds is the polish() loop trap
    readonly property int naturalHeight: {
        const n = root.pageModel.length;
        if (n === 0)
            return root.searchHeight;
        let h = root.searchHeight + root.listTopMargin + n * root.rowHeight + (n - 1) * root.rowSpacing;
        for (let i = 1; i < n; i++)
            if (root.pageModel[i].category !== root.pageModel[i - 1].category)
                h += root.runGap;
        return h;
    }

    // Pages matching the search text, each carrying its index in the unfiltered
    // pageModel so a click still selects the right page while filtered
    readonly property var filteredPages: {
        const q = searchInput.text.trim().toLowerCase();
        const out = [];
        for (let i = 0; i < root.pageModel.length; i++) {
            const p = root.pageModel[i];
            if (q === "" || p.label.toLowerCase().includes(q) || p.description.toLowerCase().includes(q))
                out.push({ page: p, idx: i });
        }
        return out;
    }

    // Clear the filter whenever the panel closes, so it doesn't reopen mid-search
    onPanelActiveChanged: if (!root.panelActive) searchInput.text = ""

    // Search field
    Rectangle {
        id: searchBg

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.searchHeight
        radius: height / 2
        color: Colors.layer
        border.width: 1
        border.color: searchInput.activeFocus ? Colors.primary : Colors.outlineVariant

        Behavior on border.color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        MaterialIcon {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "search"
            color: Colors.textMuted
            font.pixelSize: 20
        }

        Text {
            anchors.left: searchIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text.length === 0
            text: "Search settings"
            color: Colors.textMuted
            font.pixelSize: 15
        }

        TextInput {
            id: searchInput

            anchors.fill: parent
            anchors.leftMargin: 48
            anchors.rightMargin: 16
            verticalAlignment: TextInput.AlignVCenter
            color: Colors.text
            font.pixelSize: 15
            clip: true
            // Focused on open so typing filters straight away; the panel's own
            // Escape handler is out of reach once this has focus, so repeat it
            focus: root.panelActive

            Keys.onEscapePressed: {
        if (SettingsState.subPage)
            SettingsState.closeSubPage();
        else
            SettingsState.open = false;
    }
        }
    }

    // Page list
    Flickable {
        id: listFlick

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchBg.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: root.listTopMargin

        contentWidth: width
        contentHeight: listColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: listColumn

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: root.rowSpacing

            Repeater {
                model: root.filteredPages

                delegate: NavItem {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    // Categories read as runs of connected pills — a gap opens
                    // where the category changes, and the radii below round off
                    // only the ends of each run
                    Layout.topMargin: index !== 0 && runStart ? root.runGap : 0

                    page: modelData.page
                    pageIndex: modelData.idx
                    runStart: index === 0 || root.filteredPages[index - 1].page.category !== modelData.page.category
                    runEnd: index === root.filteredPages.length - 1 || root.filteredPages[index + 1].page.category !== modelData.page.category
                }
            }
        }

        // Empty state
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 24
            visible: root.filteredPages.length === 0
            text: "No settings found"
            color: Colors.textMuted
            font.pixelSize: 14
        }
    }
}
