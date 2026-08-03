import QtQuick

// Lazy dialog
Loader {
    id: root

    required property bool shown

    active: root.shown
}
