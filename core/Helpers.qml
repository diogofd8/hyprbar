pragma Singleton

import Quickshell

import qs

// Stateless operations shared by services and views. Callers own their state
// and decide when to update it.
Singleton {
    // Entries need a unique, stable key role.
    function syncModel(model, entries, key) {
        const keys = new Set(entries.map(entry => entry[key]))

        for (let i = model.count - 1; i >= 0; --i) {
            if (!keys.has(model.get(i)[key]))
                model.remove(i)
        }

        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i]
            let existing = i
            while (existing < model.count && model.get(existing)[key] !== entry[key])
                ++existing

            if (existing === model.count)
                model.insert(i, entry)
            else {
                if (existing !== i)
                    model.move(existing, i, 1)
                for (const role of Object.keys(entry)) {
                    if (model.get(i)[role] !== entry[role])
                        model.setProperty(i, role, entry[role])
                }
            }
        }
    }

    // The first entry is the fallback. Thresholds must be nonempty and sorted
    // in ascending order; a value exactly on a threshold selects that entry.
    function thresholdIndex(value, thresholds) {
        let index = 0
        for (let i = 1; i < thresholds.length; ++i) {
            if (value >= thresholds[i].threshold)
                index = i
            else
                break
        }
        return index
    }

    // Charging takes precedence over battery level. The caller supplies the
    // active palette so this helper does not own theme or UPower state.
    function batteryStatusColor(battery) {
        if (battery.charging)
            return Settings.colors.accentCharging
        if (battery.state === "empty")
            return Settings.colors.accentError
        if (battery.state === "alert")
            return Settings.colors.accentAlert
        return Settings.colors.fgMain
    }
}
