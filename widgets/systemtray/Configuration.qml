pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray as TrayService

Singleton {
    // ────── General ──────
    readonly property int widgetBoxPadding: 8

    // ------- System Tray Entries -------
    readonly property int stEntryRowSpacing: 3
    readonly property int stEntryPadding: 4

    // StatusNotifier item IDs to omit from the tray module. Use [] to show all items.
    readonly property var systemTrayBlacklist: ["blueman"]

    readonly property int contentWidth: 250

    function isVisible(item) {
        return item.status !== TrayService.Status.Passive
            && systemTrayBlacklist.indexOf(item.id) === -1
    }
}
