pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // ────── Dark Theme ──────
    readonly property QtObject dark: QtObject {
        readonly property color bgMain: "#080A0C"
        readonly property color bgTint1: "#101319"
        readonly property color bgTint2: "#181E25"
        readonly property color bgTint3: "#202831"
        readonly property color bgTint4: "#28313E"
        readonly property real hoverOpacity: 0.10
        readonly property real bgOpacity: 0.7

        readonly property color fgMain: "#7E85B2"
        readonly property color fgDark: bgMain
        readonly property color accentMain: "#7B2424"
        readonly property color accentCharging: "#85B27E"
        readonly property color accentAlert: "#B2AB7E"
        readonly property color accentError: "#B12F3B"

        readonly property color internalBatteryColor: "#DAA250"
        readonly property color externalBatteryColor: "#5088DA"
    }

    // ────── Light Theme ──────
    readonly property QtObject light: QtObject {
        readonly property color bgMain: "#F4F5F7"
        readonly property color bgTint1: "#E8EBEF"
        readonly property color bgTint2: "#DCE0E6"
        readonly property color bgTint3: "#D0D5DD"
        readonly property color bgTint4: "#C3C9D3"
        readonly property real hoverOpacity: 0.10
        readonly property real bgOpacity: 0.95

        readonly property color fgMain: "#555D8A"
        readonly property color fgDark: bgMain
        readonly property color accentMain: "#8F3030"
        readonly property color accentCharging: "#5F8F58"
        readonly property color accentAlert: "#918A4F"
        readonly property color accentError: "#A62D38"

        readonly property color internalBatteryColor: "#DAA250"
        readonly property color externalBatteryColor: "#5088DA"
    }
}