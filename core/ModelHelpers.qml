pragma Singleton

import Quickshell

// Stateless ListModel operations. Each service owns its snapshots and decides
// when to sync; rows need a unique, stable key role.
Singleton {
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
}
