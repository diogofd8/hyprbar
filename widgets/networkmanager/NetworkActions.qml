pragma Singleton

import Quickshell

import qs.core as Core

Singleton {
    function wifiIcons(model) {
        if (model.security === "open")
            return Configuration.nwWifiOpenIcon

        return Configuration.nwWifiProtectedIcon
    }

    function signalLevel(model) {
        if (model.kind !== "wifi")
            return 0

        const level = Core.Network.wifiSignalLevel(model.signalStrength)
        return Math.min(level, wifiIcons(model).length - 1)
    }

    function entryIcon(model) {
        if (model.kind === "ethernet")
            return Configuration.nwEthernetIcon

        return wifiIcons(model)[signalLevel(model)]
    }

    function connectionTypeText(model) {
        if (model.kind === "ethernet")
            return model.interfaceName

        switch (model.security) {
            case "open": return "Open"
            case "enterprise": return "Enterprise"
            case "unsupported": return "Other"
            default: return "Secured"
        }
    }

    // Security this row cannot set up inline; NetworkManager has to do it.
    function needsExternalSetup(model) {
        if (model.kind !== "wifi")
            return false

        if (model.security !== "enterprise" && model.security !== "unsupported")
            return false

        return !model.canConnect && !model.canEdit
    }
}
