import QtQuick
import Quickshell

// Config-gated panel loader
LazyLoader {
    property bool extraCondition: true
    active: Config.ready && extraCondition
}
