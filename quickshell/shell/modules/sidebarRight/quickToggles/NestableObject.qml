import QtQuick

// QtObject that allows child QtObjects (Connections, Timer, Process, ...) to
// be declared freely inside it — a plain QtObject has no default property,
// so it can't hold declarative children without this
QtObject {
    default property list<QtObject> data
}
