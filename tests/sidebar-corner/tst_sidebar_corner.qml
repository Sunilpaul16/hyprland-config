import QtQuick
import QtTest
import "../../quickshell/caelestia/custom" as Custom

Item {
    width: 200
    height: 200

    QtObject {
        id: state
        property bool sidebar: false
    }

    Item {
        id: viewport
        width: 100
        height: 100

        Custom.SidebarHotspot {
            id: hotspot
            screenState: state
        }
    }

    TestCase {
        name: "SidebarCorner"
        when: windowShown

        function init() {
            state.sidebar = false;
            hotspot.enabled = true;
        }

        function test_click_toggles_sidebar() {
            mouseClick(hotspot, 10, 10, Qt.LeftButton);
            compare(state.sidebar, true);
            mouseClick(hotspot, 10, 10, Qt.LeftButton);
            compare(state.sidebar, false);
        }

        function test_outside_corner_does_not_toggle() {
            mouseClick(viewport, 10, 70, Qt.LeftButton);
            compare(state.sidebar, false);
        }

        function test_right_click_does_not_toggle() {
            mouseClick(hotspot, 10, 10, Qt.RightButton);
            compare(state.sidebar, false);
        }

        function test_disabled_target_does_not_toggle() {
            hotspot.enabled = false;
            mouseClick(hotspot, 10, 10, Qt.LeftButton);
            compare(state.sidebar, false);
        }

        function test_target_follows_top_right_corner() {
            compare(hotspot.x, 80);
            compare(hotspot.y, 0);
            compare(hotspot.width, 20);
            compare(hotspot.height, 20);
            viewport.width = 150;
            compare(hotspot.x, 130);
            viewport.width = 100;
        }
    }
}
