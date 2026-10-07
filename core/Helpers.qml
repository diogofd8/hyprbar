pragma Singleton

import Quickshell

// Stateless model and threshold operations. Services own their state and
// decide when to update it.
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
}
