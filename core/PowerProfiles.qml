pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower as UPowerService

Singleton {
    id: root

    // Quickshell exposes profile capabilities rather than a separate daemon
    // availability property. A performance profile is the reliable positive
    // capability signal; the setter remains guarded for unsupported modes.
    readonly property bool available: root.hasPerformanceProfile
    readonly property var profile: UPowerService.PowerProfiles.profile
    readonly property bool hasPerformanceProfile:
        UPowerService.PowerProfiles.hasPerformanceProfile
    readonly property string activeProfile: root.profileName(root.profile)

    function setProfile(profile) {
        if (!root.available)
            return false

        if (profile === "power-saver")
            UPowerService.PowerProfiles.profile = UPowerService.PowerProfile.PowerSaver
        else if (profile === "balanced")
            UPowerService.PowerProfiles.profile = UPowerService.PowerProfile.Balanced
        else if (profile === "performance" && root.hasPerformanceProfile)
            UPowerService.PowerProfiles.profile = UPowerService.PowerProfile.Performance
        else
            return false

        return true
    }

    function profileName(profile) {
        switch (profile) {
        case UPowerService.PowerProfile.PowerSaver: return "power-saver"
        case UPowerService.PowerProfile.Balanced: return "balanced"
        case UPowerService.PowerProfile.Performance: return "performance"
        default: return ""
        }
    }
}
