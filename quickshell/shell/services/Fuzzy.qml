pragma Singleton
import QtQuick
import "./fuzzysort.js" as Fuzzysort

// fuzzysort wrapper
QtObject {
    id: root

    function go(query, list, options) {
        if (!Config.launcher.fuzzy)
            return root.substringGo(query, list, options);
        return Fuzzysort.go(query, list, options);
    }

    // Substring match
    function substringGo(query, list, options) {
        const key = options?.key ?? "";
        const needle = String(query).toLowerCase();
        return list.filter(o => String(o[key] ?? "").toLowerCase().includes(needle)).map(o => ({
            obj: o
        }));
    }
}
