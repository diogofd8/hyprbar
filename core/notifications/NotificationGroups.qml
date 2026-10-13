import QtQuick
import Quickshell

// A grouped view of the chronological history, sharing its notification objects.
// The owner refreshes this after history changes; there is no recurring work.
Scope {
    id: root
    required property var sourceModel
    readonly property alias model: groups

    ListModel { id: groups }
    Component { id: groupComponent; NotificationGroup {} }

    function keyFor(entry): string {
        return entry.desktopEntry ? "desktop:" + entry.desktopEntry : "name:" + entry.appName
    }

    // Move existing rows instead of resetting them, preserving card delegates
    // and their open details when a newer notification changes the order.
    function syncModel(model, role, values): void {
        for (let i = 0; i < values.length; ++i) {
            if (i < model.count && model.get(i)[role] === values[i])
                continue
            let existing = i + 1
            while (existing < model.count && model.get(existing)[role] !== values[i])
                ++existing
            if (existing < model.count)
                model.move(existing, i, 1)
            else
                model.insert(i, {[role]: values[i]})
        }
        if (model.count > values.length)
            model.remove(values.length, model.count - values.length)
    }

    function refresh(): void {
        if (!root.sourceModel)
            return
        const existing = new Map()
        for (let i = 0; i < groups.count; ++i) {
            const group = groups.get(i).group
            existing.set(group.key, group)
        }
        const membersByKey = new Map()
        for (let i = 0; i < root.sourceModel.count; ++i) {
            const entry = root.sourceModel.get(i).entry
            const key = root.keyFor(entry)
            if (!membersByKey.has(key))
                membersByKey.set(key, [])
            membersByKey.get(key).push(entry)
        }
        // Source order supplies both the group order and each group's order.
        const orderedGroups = []
        for (const [key, members] of membersByKey) {
            const group = existing.get(key) || groupComponent.createObject(root, {key: key})
            root.syncModel(group.model, "entry", members)
            group.latest = members[0]
            orderedGroups.push(group)
            existing.delete(key)
        }
        root.syncModel(groups, "group", orderedGroups)
        for (const group of existing.values()) {
            group.latest = null
            group.model.clear()
            group.destroy()
        }
    }

    Component.onCompleted: root.refresh()
}
