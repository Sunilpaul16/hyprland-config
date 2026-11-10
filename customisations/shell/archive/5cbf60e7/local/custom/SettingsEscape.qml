import QtQuick

Shortcut {
    signal closeRequested

    sequence: "Escape"
    context: Qt.WindowShortcut
    autoRepeat: false
    onActivated: closeRequested()
}
