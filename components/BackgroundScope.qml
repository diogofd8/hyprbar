import QtQuick
import Quickshell

// A logical paint owner, not a layout child. Project only its paint into the
// nearest explicit background scope; retain its QObject ownership here.
QtObject {
    id: root

    required property Item sourceItem
    // Targets come from BackgroundSurface.paintTarget or another scope.
    property BackgroundTarget target: root.findTarget(root.sourceItem)
    property bool disposing: false
    readonly property point origin: root.mapOrigin()
    default property alias paint: projectedPaint.data
    readonly property BackgroundTarget paintTarget: BackgroundTarget {
        id: projectedPaint
        // Empty clip scopes stay outside layouts when no surface is present.
        parent: root.target ?? (projectedPaint.children.length > 0 ? root.sourceItem : null)
        sourceItem: root.sourceItem
        x: root.origin.x
        y: root.origin.y
        width: root.sourceItem?.width ?? 0
        height: root.sourceItem?.height ?? 0
        visible: root.sourceItem?.visible ?? false
        clip: root.sourceItem?.clip ?? false
        opacity: root.paintOpacity()
        z: root.paintZ()
        transform: Matrix4x4 { matrix: root.paintTransform() }
    }

    readonly property TransformWatcher watcher: TransformWatcher {
        a: root.disposing ? null : root.target?.coordinateItem ?? null
        b: root.disposing || !root.target ? null : root.sourceItem
    }

    Component.onDestruction: root.disposing = true

    // ────── Helper Functions ──────
    function findTarget(source: Item): BackgroundTarget {
        for (let item = source; item; item = item.parent) {
            // Paint already under a capture root renders there directly.
            if (item.backgroundPaint)
                return null
            const scope = item.backgroundScope
            if (scope && scope !== root && scope.target)
                return scope.paintTarget
            if (item.backgroundTarget)
                return item.backgroundTarget
        }
        return source?.QsWindow.window?.backgroundTarget ?? null
    }

    function paintOpacity(): real {
        if (!root.target || !root.sourceItem)
            return 1
        const boundary = root.target.sourceItem
        let result = 1
        for (let item = root.sourceItem; item && item !== boundary; item = item.parent)
            result *= item.opacity
        return result
    }

    function paintZ(): real {
        if (!root.target || !root.sourceItem)
            return root.sourceItem?.z ?? 0
        const order = root.target.paintOrder
        const index = order.indexOf(projectedPaint)
        const branch = root.target.sourcePath(root.sourceItem)[0]
        // Own base paint uses z=-1. Original negative branches stay below it;
        // other branches follow in their original sibling/z order above it.
        return branch?.z < 0 ? index - order.length - 1 : index
    }

    function paintTransform(): matrix4x4 {
        root.watcher.transform
        if (!root.target || !root.sourceItem)
            return Qt.matrix4x4()
        // Nested scopes already mirror their layout owner. Mapping to that
        // owner avoids invalidations caused by updates in the paint tree.
        const coordinateItem = root.target.coordinateItem
        const xAxis = root.sourceItem.mapToItem(coordinateItem, 1, 0)
        const yAxis = root.sourceItem.mapToItem(coordinateItem, 0, 1)
        return Qt.matrix4x4(
            xAxis.x - root.origin.x, yAxis.x - root.origin.x, 0, 0,
            xAxis.y - root.origin.y, yAxis.y - root.origin.y, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1)
    }

    function mapOrigin(): point {
        root.watcher.transform
        return root.target && root.sourceItem
            ? root.sourceItem.mapToItem(root.target.coordinateItem, 0, 0)
            : Qt.point(0, 0)
    }
}
