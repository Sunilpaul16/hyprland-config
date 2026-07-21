import QtQuick

// Declarative quick-toggle definition. `toggled` describes the feature
// itself (bound to real state); whether a toggle is shown/ordered is a
// separate concern living in Persistent.quickToggleLayout — the two can't
// collide the way a single overloaded "active" property could
// (comparison.md #24, resolves §4.5)
NestableObject {
    required property string toggleId
    required property string icon
    property string name: ""
    property bool toggled: false
    // Real backend present but temporarily unavailable (e.g. no Bluetooth
    // adapter) — distinct from a toggle simply not existing, which has no
    // entry here at all (matches end-4: no dead settings/gaming placeholders)
    property bool available: true
    required property var mainAction
    property var altAction: null
}
