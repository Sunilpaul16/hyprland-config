import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services

Scope {
    IpcHandler {
        target: "launcher"

        function wallpaper(): void {
            const state = ShellState.forActive();
            const components = ShellState.componentsForActive();
            if (!state || !components)
                return;
            state.launcher = true;
            Qt.callLater(() => {
                const search = components.find("launcherSearch");
                if (search) {
                    search.text = `${GlobalConfig.launcher.actionPrefix}wallpaper `;
                    search.forceActiveFocus();
                }
            });
        }
    }

}
