pragma Singleton
import QtQuick
import "./fuzzysort.js" as Fuzzysort

// Thin wrapper around the vendored fuzzysort.js — lets the four importers
// (Apps/Wallpapers/Cliphist/Commands) reference one singleton instead of
// each importing the .js file directly
QtObject {
    function go(query, list, options) {
        return Fuzzysort.go(query, list, options);
    }
}
