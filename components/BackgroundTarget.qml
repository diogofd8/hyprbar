import QtQuick

// Shared coordinate contract for a surface and its nested paint containers.
Item {
    id: root

    required property Item sourceItem
    property Item coordinateItem: root.sourceItem
    readonly property bool backgroundPaint: true
    readonly property var paintOrder: root.orderedPaints()

    // ────── Helper Functions ──────
    // Visual parenting can finish in a different order from QML construction.
    // Sort each group's projected children by their original visual branches;
    // geometry changes do not invalidate this binding.
    function orderedPaints(): list<Item> {
        return root.children.filter(child => child?.backgroundPaint && child.sourceItem)
            .sort((a, b) => root.compareSources(a.sourceItem, b.sourceItem))
    }

    function sourcePath(source: Item): list<Item> {
        const path = []
        for (let item = source; item && item !== root.sourceItem; item = item.parent)
            path.unshift(item)
        return path
    }

    function compareSources(a: Item, b: Item): int {
        const left = root.sourcePath(a)
        const right = root.sourcePath(b)
        for (let i = 0; i < Math.min(left.length, right.length); ++i) {
            if (left[i] === right[i])
                continue
            if (left[i].z !== right[i].z)
                return left[i].z < right[i].z ? -1 : 1
            const siblings = left[i].parent?.children ?? []
            return siblings.indexOf(left[i]) - siblings.indexOf(right[i])
        }
        return left.length - right.length
    }
}
