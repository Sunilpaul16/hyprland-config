import QtQuick

// Lets child QtObjects be declared freely inside — plain QtObject has no default property
QtObject {
    default property list<QtObject> data
}
