pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

import qs

Singleton {
    id: root

    // ────── Public API ──────
    // Each reading is {present, value, state, charging, active, icon}, with
    // `value` a whole percent and `icon` already resolved to a glyph. The UI
    // only has to map `state` onto a colour.
    readonly property var internal: reading(deviceFor(Settings.internalBatteryPath))
    readonly property var external: reading(deviceFor(Settings.externalBatteryPath))

    // The pack the firmware is currently charging or discharging. Its level is
    // the one the bar shows as *the* percentage.
    readonly property var active: reading(deviceFor(activePath))

    readonly property bool onAc: !UPower.onBattery
    readonly property bool ready: batteries.length > 0

    // ────── Active Pack Detection ──────
    // Power Bridge moves exactly one pack in or out at a time and parks the
    // other at a changeRate of exactly 0. State is not usable for this: UPower
    // reports the idle pack as FullyCharged even when it is sitting at 98%.
    readonly property string activePath: {
        let flowing = null

        for (const battery of batteries) {
            if (!battery.isPresent || battery.changeRate === 0)
                continue

            if (!flowing || Math.abs(battery.changeRate) > Math.abs(flowing.changeRate))
                flowing = battery
        }

        if (flowing)
            return flowing.nativePath

        // Nothing is moving — normally mains power with everything topped up.
        // Prefer a pack that still has room, so the indicator lands somewhere
        // meaningful rather than flickering between two idle packs.
        for (const battery of batteries) {
            if (battery.isPresent && battery.state !== UPowerDeviceState.FullyCharged)
                return battery.nativePath
        }

        for (const battery of batteries) {
            if (battery.isPresent)
                return battery.nativePath
        }

        return ""
    }

    readonly property var batteries: {
        const found = []

        for (const device of UPower.devices.values) {
            if (device.isLaptopBattery && device.ready)
                found.push(device)
        }

        return found
    }

    function deviceFor(nativePath) {
        for (const battery of batteries) {
            if (battery.nativePath === nativePath)
                return battery
        }

        return null
    }

    function reading(device) {
        // An absent pack keeps the "empty" state on purpose: it is the state
        // the view already paints with the error colour, and `present` is
        // there to tell "removed" apart from "flat" when that matters.
        if (!device || !device.isPresent) {
            return {
                present: false,
                value: 0,
                state: "empty",
                charging: false,
                active: false,
                icon: Settings.batteryOffIcon
            }
        }

        // Round once, here, so the number on screen, the icon bucket and the
        // state can never disagree with each other at a boundary.
        const percent = Math.round(device.percentage * 100)
        const charging = device.state === UPowerDeviceState.Charging
        const state = resolveState(percent, Settings.batteryLevelThresholds)

        return {
            present: true,
            value: percent,
            state: state,
            charging: charging,
            active: device.nativePath === root.activePath,
            icon: resolveIcon(percent, charging, state)
        }
    }

    // The first icon belongs to the lowest state and the last to the highest,
    // so moving the "full" threshold moves the full glyph with it. Everything
    // between shares the remaining icons evenly across the span those middle
    // states cover — neither endpoint steals a bucket from the middle.
    function resolveIcon(percent, charging, state) {
        if (charging)
            return Settings.batteryChargingIcon

        const icons = Settings.batteryCtrlIcon
        const thresholds = Settings.batteryLevelThresholds
        const lastIcon = icons.length - 1

        if (thresholds.length < 2 || lastIcon < 2)
            return icons[0]

        const highest = thresholds[thresholds.length - 1]

        if (state === thresholds[0].state)
            return icons[0]

        if (state === highest.state)
            return icons[lastIcon]

        const lower = thresholds[1].threshold
        const span = highest.threshold - lower

        if (span <= 0)
            return icons[1]

        const index = 1 + Math.floor((percent - lower) / span * (lastIcon - 1))

        return icons[Math.max(1, Math.min(lastIcon - 1, index))]
    }

    function resolveState(value, thresholds) {
        let state = "empty"

        for (const entry of thresholds) {
            if (value >= entry.threshold)
                state = entry.state
            else
                break
        }

        return state
    }

    // ────── Debug Trace ──────
    // readonly property string logLine:
    //     "BATTERY: " + active.value + "% (" + active.state
    //     + (active.charging ? ", charging" : "") + ")"
    //     + " active=" + (activePath || "none")
    //     + " | internal " + internal.value + "% " + internal.state
    //     + (internal.active ? " *" : "") + " " + internal.icon
    //     + " | external " + external.value + "% " + external.state
    //     + (external.active ? " *" : "") + " " + external.icon
    //     + " | onAc=" + onAc

    // onLogLineChanged: if (ready) console.log(logLine)
}
