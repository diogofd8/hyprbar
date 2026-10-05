pragma Singleton

import Quickshell

Singleton {
    // ────── Profile Control Backend ──────
    // tlp-pd implements the standard Power Profiles API while keeping TLP as
    // the underlying engine. "tlp" remains available for direct commands on
    // systems where those commands have been separately authorised.
    readonly property string powerProfileBackend: "power-profiles-daemon"

    // ────── Battery Names ──────
    readonly property string internalBat: "01AV421"
    readonly property string externalBat: "01AV427"

    // ────── Icons ──────
    readonly property var powerMode: ({
        "power-saver": "󰌪",
        "balanced": "󰗑",
        "performance": "",
    })
    readonly property var restoreTlpButton: "󰁯"

    readonly property int contentWidth: 275
}
