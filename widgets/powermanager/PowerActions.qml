pragma Singleton

import Quickshell

import qs.core as Core

Singleton {
    function setTlpProfile(profile: string): void {
        if (["performance", "balanced", "power-saver"].includes(profile))
            Quickshell.execDetached(["tlp", profile])
    }

    function setPowerProfile(profile: string): bool {
        return Core.PowerProfiles.setProfile(profile)
    }

    function setConfiguredPowerProfile(profile: string, backend: string): bool {
        if (backend === "power-profiles-daemon")
            return setPowerProfile(profile)

        setTlpProfile(profile)
        return true
    }
}