import QtQuick

import qs

// The bar's NumberAnimation. Defaults to the in-popout expand/collapse timing,
// so most Behaviors need only `Anim {}`; override duration or
// easing.bezierCurve with another Motion token where an action has its own.
NumberAnimation {
    duration: Motion.normalMs
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.inOutCurve
}
