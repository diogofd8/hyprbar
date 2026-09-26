pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

import qs

Singleton {
    id: root

    // The popup owns discovery demand. No scans are requested by the bar.
    property bool discoveryActive: false

    // ────── Public API ──────
    // Each reading is {present, value, state, charging, active, icon}, with
    // `value` a whole percent and `icon` already resolved to a glyph. The UI
    // only has to map `state` onto a colour.
    readonly property var internal: reading(deviceFor(Settings.internalBatteryPath))
    readonly property var external: reading(deviceFor(Settings.externalBatteryPath))

    // The pack the firmware is currently charging or discharging. Its level is
    // the one the bar shows as *the* percentage.
    readonly property var active: reading(deviceFor(activePath))

    // The aggregate UPower display device combines all system batteries. It
    // is useful to consumers that need the same value UPower shows in its
    // desktop summary, but is deliberately not included in the entry models.
    readonly property var display: reading(UPower.displayDevice)

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

    // Every individual rechargeable UPower device other than the laptop
    // packs. This includes mice, keyboards, headsets and other devices when
    // the daemon exposes their battery through UPower.
    readonly property var peripheralBatteries: {
        const found = []

        for (const device of UPower.devices.values) {
            if (!device.ready || !device.isPresent)
                continue
            if (device.isLaptopBattery || device === UPower.displayDevice)
                continue
            if (device.type === UPowerDeviceType.LinePower)
                continue
            found.push(device)
        }

        return found
    }

    readonly property string entrySignature: {
        const devices = UPower.devices.values
        return devices.map(device => [
            device.nativePath, device.ready, device.isPresent,
            device.powerSupply, device.isLaptopBattery, device.type,
            device.model, device.percentage, device.state,
            device.changeRate, device.timeToEmpty, device.timeToFull,
            device.healthPercentage, device.healthSupported
        ].join(":")).join("\n")
    }

    readonly property var batteryEntrySnapshots: makeEntries(batteries, "battery")
    readonly property var peripheralEntrySnapshots: makeEntries(peripheralBatteries, "device")

    onEntrySignatureChanged: {
        root.refreshEntryModels()
    }

    Component.onCompleted: root.refreshEntryModels()

    ListModel { id: batteryEntries }
    ListModel { id: peripheralEntries }

    readonly property var batteryEntryModel: batteryEntries
    readonly property var peripheralEntryModel: peripheralEntries

    function refreshEntryModels() {
        syncModel(batteryEntries, root.batteryEntrySnapshots)
        syncModel(peripheralEntries, root.peripheralEntrySnapshots)
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
                icon: Settings.batteryOffIcon,
                name: "",
                status: "",
                statusText: "",
                autonomy: 0,
                fullIn: 0,
                health: 0,
                healthSupported: false
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
            icon: resolveIcon(percent, charging, state),
            name: device.model || device.nativePath,
            status: statusName(device.state),
            statusText: statusText(device.state),
            autonomy: device.timeToEmpty,
            fullIn: device.timeToFull,
            health: Math.round(device.healthPercentage),
            healthSupported: device.healthSupported
        }
    }

    function makeEntries(devices, kind) {
        return devices.map(device => {
            const value = reading(device)
            return {
                id: device.nativePath,
                kind: kind,
                name: value.name || (kind === "battery"
                    ? "Battery (" + device.nativePath + ")"
                    : UPowerDeviceType.toString(device.type)),
                icon: kind === "battery"
                    ? value.icon : peripheralIcon(device.type),
                value: value.value,
                state: value.state,
                status: value.status,
                statusText: value.statusText,
                charging: value.charging,
                active: value.active,
                autonomy: value.autonomy,
                fullIn: value.fullIn,
                health: value.health,
                healthSupported: value.healthSupported
            }
        })
    }

    function syncModel(model, entries) {
        const ids = new Set(entries.map(entry => entry.id))
        for (let i = model.count - 1; i >= 0; --i) {
            if (!ids.has(model.get(i).id))
                model.remove(i)
        }

        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i]
            let existing = i
            while (existing < model.count && model.get(existing).id !== entry.id)
                ++existing

            if (existing === model.count)
                model.insert(i, entry)
            else {
                if (existing !== i)
                    model.move(existing, i, 1)
                for (const key of Object.keys(entry)) {
                    if (model.get(i)[key] !== entry[key])
                        model.setProperty(i, key, entry[key])
                }
            }
        }
    }

    function statusName(state) {
        return UPowerDeviceState.toString(state)
    }

    function statusText(state) {
        switch (state) {
        case UPowerDeviceState.Charging: return "Charging"
        case UPowerDeviceState.Discharging: return "Discharging"
        case UPowerDeviceState.FullyCharged: return "Fully charged"
        case UPowerDeviceState.PendingCharge: return "Waiting to charge"
        case UPowerDeviceState.PendingDischarge: return "Waiting to discharge"
        case UPowerDeviceState.Empty: return "Empty"
        default: return "Unknown"
        }
    }

    function peripheralIcon(type) {
        switch (type) {
        case UPowerDeviceType.Mouse: return "󰍽"
        case UPowerDeviceType.Keyboard: return "󰌌"
        case UPowerDeviceType.Headset: return "󰋎"
        case UPowerDeviceType.Headphones: return "󰋋"
        case UPowerDeviceType.Phone: return "󰏲"
        case UPowerDeviceType.GamingInput: return "󰊗"
        case UPowerDeviceType.Tablet: return "󰓶"
        case UPowerDeviceType.Camera: return "󰄀"
        default: return Settings.batteryCtrlIcon[Settings.batteryCtrlIcon.length - 1]
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
