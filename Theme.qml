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
        readonly property color bgMain: "#F5F6F8"
        readonly property color bgTint1: "#ECEEF2"
        readonly property color bgTint2: "#E2E5EA"
        readonly property color bgTint3: "#D7DBE2"
        readonly property color bgTint4: "#CBD0D9"
        readonly property real hoverOpacity: 0.10

        readonly property color fgMain: "#555C82"
        readonly property color fgDark: bgMain
        readonly property color accentMain: "#8F3030"
        readonly property color accentCharging: "#4F8A48"
        readonly property color accentAlert: "#8A8145"
        readonly property color accentError: "#A82D3A"

        readonly property color internalBatteryColor: "#DAA250"
        readonly property color externalBatteryColor: "#5088DA"
    }
}