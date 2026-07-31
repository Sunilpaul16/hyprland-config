pragma Singleton
import QtQuick
import "./fuzzysort.js" as Fuzzysort

// Thin wrapper around the vendored fuzzysort.js — lets the four importers
// (Apps/Wallpapers/Cliphist/Commands) reference one singleton instead of
// each importing the .js file directly
QtObject {
    id: root

    function go(query, list, options) {
        if (!Config.launcher.fuzzy)
            return root.substringGo(query, list, options);
        return Fuzzysort.go(query, list, options);
    }

    // Plain case-insensitive substring match, wrapped in fuzzysort's {obj}
    // result shape so no caller has to know which mode is active. Keeps the
    // list's own order rather than ranking
    function substringGo(query, list, options) {
        const key = options?.key ?? "";
        const needle = String(query).toLowerCase();
        return list.filter(o => String(o[key] ?? "").toLowerCase().includes(needle)).map(o => ({
            obj: o
        }));
    }
}
