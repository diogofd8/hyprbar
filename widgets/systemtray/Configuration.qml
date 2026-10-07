pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray as TrayService

Singleton {
    // ------- System Tray Entries -------
    readonly property int stEntryPadding: 4

    // StatusNotifier item IDs to omit from the tray module. Use [] to show all items.
    readonly property var systemTrayBlacklist: ["blueman"]

    function isVisible(item) {
        return item.status !== TrayService.Status.Passive
            && systemTrayBlacklist.indexOf(item.id) === -1
    }
}
