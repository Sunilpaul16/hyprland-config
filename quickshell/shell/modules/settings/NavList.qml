import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

// Nav pane
Item {
    id: root

    required property var pageModel
    property bool panelActive: false

    readonly property int searchHeight: 46
    readonly property int listTopMargin: 14
    readonly property int rowSpacing: 3
    readonly property int runGap: 12
    // Row height
    readonly property int rowHeight: 66

    // Natural height
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

    // Filtered pages
    readonly property var filteredPages: {
        const q = searchInput.text.trim().toLowerCase();
        const out = [];
        for (let i = 0; i < root.pageModel.length; i++) {
            const p = root.pageModel[i];
            const haystack = `${p.label} ${p.description} ${p.key} ${p.category} ${p.keywords ?? ""}`.toLowerCase();
            if (q === "" || haystack.includes(q))
                out.push({ page: p, idx: i });
        }
        return out;
    }

    // Clear on close
    onPanelActiveChanged: if (!root.panelActive) searchInput.text = ""

    // Search field
    Rectangle {
        id: searchBg

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.searchHeight
        radius: Motion.rounding.card
        color: searchInput.activeFocus ? Colors.tint(Colors.layer, Colors.primary, 0.10) : Colors.layer

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

        MaterialIcon {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: Motion.spacing.xlarge
            anchors.verticalCenter: parent.verticalCenter
            text: "search"
            color: searchInput.activeFocus ? Colors.primary : Colors.textMuted
            font.pixelSize: Motion.fontSize.display

            Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
        }

        StyledText {
            anchors.left: searchIcon.right
            anchors.leftMargin: Motion.spacing.large
            anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text.length === 0
            text: "Search settings"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.title
        }

        TextInput {
            id: searchInput

            anchors.fill: parent
            anchors.leftMargin: 48
            anchors.rightMargin: Motion.spacing.xlarge
            verticalAlignment: TextInput.AlignVCenter
            color: Colors.text
            font.pixelSize: Motion.fontSize.title
            clip: true
            // Focus on open
            focus: root.panelActive

            Keys.onReturnPressed: {
                if (root.filteredPages.length === 0)
                    return;
                SettingsState.currentPageIdx = root.filteredPages[0].idx;
                searchInput.text = "";
            }
            Keys.onEnterPressed: event => {
                if (root.filteredPages.length === 0)
                    return;
                SettingsState.currentPageIdx = root.filteredPages[0].idx;
                searchInput.text = "";
                event.accepted = true;
            }
            Keys.onEscapePressed: {
                if (searchInput.text.length > 0)
                    searchInput.text = "";
                else if (SettingsState.subPage)
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
                    // Category runs
                    Layout.topMargin: index !== 0 && runStart ? root.runGap : 0

                    page: modelData.page
                    pageIndex: modelData.idx
                    runStart: index === 0 || root.filteredPages[index - 1].page.category !== modelData.page.category
                    runEnd: index === root.filteredPages.length - 1 || root.filteredPages[index + 1].page.category !== modelData.page.category
                }
            }
        }

        // Empty state
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Motion.spacing.section
            visible: root.filteredPages.length === 0
            text: "No settings found"
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.subhead
        }
    }
}
