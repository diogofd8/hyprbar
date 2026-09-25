pragma Singleton

import Quickshell

Singleton {
    // BlueZ hands out a freedesktop icon name; the bar draws a glyph font.
    function entryIcon(model) {
        const mapping = Configuration.btEntryMapping
        let fallback = mapping[mapping.length - 1].icon

        for (let i = 0; i < mapping.length; ++i) {
            if (mapping[i].device === "unknown") fallback = mapping[i].icon
            if (mapping[i].device === model.icon) return mapping[i].icon
        }

        return fallback
    }

    // The single line under the row. First matching case wins.
    function statusText(model) {
        if (model.errorMessage.length > 0) return model.errorMessage

        switch (model.state) {
            // The passkey prompt belongs to the system Bluetooth agent, not to
            // this widget, so the row says where the answer is owed rather
            // than leaving the user waiting on a bar that cannot ask.
            case "Pairing": return "Pairing… confirm the request"
            case "Connecting": return "Connecting…"
            case "Disconnecting": return "Disconnecting…"
            case "Removing": return "Removing…"
            default: return ""
        }
    }

    // Only connected devices carry detail worth expanding: the type is already
    // in the glyph, so the rest of the fleet has nothing to show.
    function canExpand(model) {
        return model.connected
    }

    function batteryText(model) {
        return model.batteryAvailable ? model.battery + "%" : "None"
    }
}
