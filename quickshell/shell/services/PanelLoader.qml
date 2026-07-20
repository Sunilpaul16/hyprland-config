import QtQuick
import Quickshell

// Gates a panel on Config.ready so it can't read config before the
// FileView has loaded; extraCondition gives per-panel feature flags for free
LazyLoader {
    property bool extraCondition: true
    active: Config.ready && extraCondition
}
