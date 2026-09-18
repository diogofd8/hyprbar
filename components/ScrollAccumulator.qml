import QtQuick

import qs

// A notched wheel reports 120 per detent, but high-resolution wheels and
// touchpads send far smaller deltas. Accumulating means one detent is always
// exactly one step, and fine scrolling still adds up instead of either firing
// constantly or being discarded.
//
// State is per-instance, so this is an object a button owns, not a singleton.
QtObject {
    id: root

    // +1 per notch up, -1 per notch down, already normalised. Emitted once
    // per step, so a single large delta reports each step it crossed.
    signal stepped(int steps)

    // Per-instance so a button can ask for a coarser or finer wheel than the
    // shared default without touching it for everything else.
    property int threshold: Settings.actionScrollDelta

    property int accumulated: 0

    function accumulate(delta) {
        root.accumulated += delta

        while (root.accumulated >= root.threshold) {
            root.accumulated -= root.threshold
            root.stepped(1)
        }

        while (root.accumulated <= -root.threshold) {
            root.accumulated += root.threshold
            root.stepped(-1)
        }
    }
}
