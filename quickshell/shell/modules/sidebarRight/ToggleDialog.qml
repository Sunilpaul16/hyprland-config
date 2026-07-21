import QtQuick

// Lazily instantiates its dialog only while shown (comparison.md #25)
Loader {
    id: root

    required property bool shown

    active: root.shown
}
