pragma Singleton

import QtQuick
import Quickshell

// Every animation timing and curve in the popouts. Use `Anim {}`
// (components/Anim.qml), which defaults to normalMs + inOutCurve, and override
// only what an action needs.
Singleton {
    // ────── Durations ──────
    readonly property int fastMs: 150               // small flips on the bar (tray chevron)
    readonly property int normalMs: 200             // expand/collapse and slides inside a popout
    readonly property int popoutStartMs: 24
    readonly property int popoutOpenMs: 300
    readonly property int popoutCloseMs: 210
    readonly property int popoutMorphMs: 300
    readonly property int popoutCrossfadeMs: 150

    // ────── Distances ──────
    readonly property real popoutOffset: 8          // slide of the open/close reveal

    // ────── Curves (Easing.BezierSpline control points) ──────
    // Grows, shrinks or flips in place: row heights, chevrons, margins
    readonly property list<real> inOutCurve: [0.65, 0, 0.35, 1, 1, 1]
    // Moves somewhere and settles: popout morph, page slides
    readonly property list<real> standardCurve: [0.2, 0, 0, 1, 1, 1]
    // Popout open (decelerates) and close (accelerates)
    readonly property list<real> enterCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property list<real> exitCurve: [0.3, 0, 0.8, 0.15, 1, 1]
}
