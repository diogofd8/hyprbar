pragma Singleton

import Quickshell
import Quickshell.Io

import qs.core as Core

Singleton {
    id: root

    property string requestedPowerMode: ""
    readonly property bool resettingTlpProfile: tlpResetProcess.running

    function setTlpProfile(profile: string): void {
        if (["performance", "balanced", "power-saver"].includes(profile))
            Quickshell.execDetached(["tlpctl", profile])
    }

    function setPowerProfile(profile: string): bool {
        return Core.PowerProfiles.setProfile(profile)
    }

    function setConfiguredPowerProfile(profile: string, backend: string): bool {
        if (profile === "auto")
            return startTlpAutoProfileReset()

        if (root.resettingTlpProfile)
            return false

        if (backend === "power-profiles-daemon") {
            if (!setPowerProfile(profile))
                return false
        } else {
            setTlpProfile(profile)
        }

        root.requestedPowerMode = profile
        Core.PowerProfiles.setSettingMode("manual")
        return true
    }

    // tlpctl does not allow setting the profile to "auto", so we have to use the tlp command directly
    // it works without a password because the user is in the sudoers file for this command
    // $USER ALL=(root) NOPASSWD: /usr/bin/tlp start
    function startTlpAutoProfileReset(): bool {
        if (root.resettingTlpProfile)
            return false

        tlpResetProcess.running = true
        return true
    }

    Process {
        id: tlpResetProcess

        command: ["sudo", "-n", "/usr/bin/tlp", "start"]

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                Core.PowerProfiles.setSettingMode("auto")
        }
    }
}