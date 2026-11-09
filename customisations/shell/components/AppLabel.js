function title(Hypr, DesktopEntries, Tr) {
    const appClass = Hypr.activeToplevel?.lastIpcObject.class ?? "";
    const appName = appClass ? (DesktopEntries.heuristicLookup(appClass)?.name || appClass)
                             : Tr.trCtx("Desktop", "shown when no window is focused");
    const special = Hypr.focusedMonitor?.lastIpcObject.specialWorkspace?.name ?? "";
    if (special) {
        const scratchpads = Hypr.scratchpadNames;
        const index = scratchpads.indexOf(special);
        const label = scratchpads.length > 1 && index >= 0 ? "Scratchpad " + (index + 1) : "Scratchpad";
        return label + " · " + appName;
    }
    return appName;
}
