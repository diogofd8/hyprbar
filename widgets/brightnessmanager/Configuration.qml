pragma Singleton

import Quickshell

Singleton {
    // ------- Brightness Settings -------
    readonly property int nightTemperatureK: 4000
    readonly property int neutralTemperatureK: 6500

    // ────── Icons ──────
    readonly property string nightModeIcon: "󰥟"
    readonly property string displayEntryIcon: "󰍹"
    readonly property string keyboardEntryIcon: "󰥻"

    readonly property int contentWidth: 250
}
