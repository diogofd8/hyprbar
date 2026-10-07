pragma Singleton

import Quickshell

import qs.core as Core

Singleton {
    function toggleNightLight() {
        const command = Core.Backlight.nightLightEnabled
            ? ["hyprctl", "hyprsunset", "identity"]
            : ["hyprctl", "hyprsunset", "temperature",
                String(Configuration.nightTemperatureK)]
        Core.Backlight.runNightLightCommand(command)
    }

    function nightTemperatureText(enabled, temperature) {
        // Hyprsunset keeps its last temperature value in identity mode, but
        // applies no color transform until the filter is enabled again.
        return String(enabled ? temperature : Configuration.neutralTemperatureK)
    }

    function entryName(model) {
        return model.connector ? model.name + " (" + model.connector + ")" : model.name
    }
}
