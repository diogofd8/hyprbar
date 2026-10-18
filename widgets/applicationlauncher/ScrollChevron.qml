import QtQuick

import qs
import qs.components
import qs.core as Core

// Keep layout dimensions upright while rotating the painted chevron.
Item {
    id: root

    property bool pointUp: false
    property int leftCap: Core.ChevronGeometry.Cap.Notch
    property color bgFill: Settings.colors.background.accent

    implicitWidth: Configurations.scrollBarWidth
    implicitHeight: Configurations.scrollBarChevronHeight

    Chevron {
        x: root.pointUp ? 0 : root.width
        y: root.pointUp ? root.height : 0
        width: root.height
        height: root.width
        transformOrigin: Item.TopLeft
        rotation: root.pointUp ? -90 : 90
        leftCap: root.leftCap
        rightCap: Core.ChevronGeometry.Cap.Point
        // Wide, short chevrons must keep their caps from crossing.
        leftCapProgress: root.capProgress()
        rightCapProgress: root.capProgress()
        bgFill: root.bgFill
    }

    // ────── Helper Functions ──────
    function capProgress(): real {
        const capDepth = Core.ChevronGeometry.calcCapWidth(root.width)
        return capDepth > 0 ? Math.min(1, root.height / (2 * capDepth)) : 0
    }
}
