pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property int fastMs: 150
    readonly property int rowExpandMs: 200
    readonly property int popoutStartMs: 24
    readonly property int popoutOpenMs: 300
    readonly property int popoutCloseMs: 210
    readonly property int popoutMorphMs: 300
    readonly property int popoutCrossfadeMs: 150

    readonly property var enterCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var exitCurve: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var morphCurve: [0.2, 0, 0, 1, 1, 1]
}
