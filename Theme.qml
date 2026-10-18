pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property QtObject dark: QtObject {
        id: darkTheme

        readonly property QtObject background: QtObject {
            readonly property color highlight: "#7E85B2"
            readonly property real dimOpacity: 0.7
            readonly property color imagePlaceholder: "#7E85B2"
            readonly property color main: "#080A0C"
            readonly property color tint1: "#101319"
            readonly property color tint2: "#181E25"
            readonly property color tint3: "#202831"
            readonly property color tint4: "#28313E"
            readonly property color accent: "#7B2424"
            readonly property color charging: "#85B27E"
            readonly property color error: "#B12F3B"
            readonly property color spotify: "#1DB954"
            readonly property real opacity: 0.7
            readonly property real hoverOpacity: 0.10
            readonly property real hoverOpacityStrong: 2 * hoverOpacity
            readonly property color border: Qt.alpha(highlight, hoverOpacity)
        }

        readonly property QtObject foreground: QtObject {
            readonly property color main: "#7E85B2"
            readonly property color accent: "#7B2424"
            readonly property color charging: "#85B27E"
            readonly property color alert: "#B2AB7E"
            readonly property color error: "#B12F3B"
            readonly property color internalBattery: "#DAA250"
            readonly property color externalBattery: "#5088DA"
            readonly property color contrast: "#080A0C"
            readonly property color muted: Qt.tint(darkTheme.background.main, Qt.alpha(main, dimOpacity))
            readonly property real dimOpacity: 0.85
            readonly property real disabledOpacity: 0.4
        }
    }

    readonly property QtObject light: QtObject {
        id: lightTheme

        readonly property QtObject background: QtObject {
            readonly property color highlight: "#555D8A"
            readonly property real dimOpacity: 0.7
            readonly property color imagePlaceholder: "#555D8A"
            readonly property color main: "#F4F5F7"
            readonly property color tint1: "#E8EBEF"
            readonly property color tint2: "#DCE0E6"
            readonly property color tint3: "#D0D5DD"
            readonly property color tint4: "#C3C9D3"
            readonly property color accent: "#8F3030"
            readonly property color charging: "#5F8F58"
            readonly property color error: "#A62D38"
            readonly property color spotify: "#1DB954"
            readonly property real opacity: 0.95
            readonly property real hoverOpacity: 0.10
            readonly property real hoverOpacityStrong: 2 * hoverOpacity
            readonly property color border: Qt.alpha(highlight, hoverOpacity)
        }

        readonly property QtObject foreground: QtObject {
            readonly property color main: "#555D8A"
            readonly property color accent: "#8F3030"
            readonly property color charging: "#5F8F58"
            readonly property color alert: "#918A4F"
            readonly property color error: "#A62D38"
            readonly property color internalBattery: "#DAA250"
            readonly property color externalBattery: "#5088DA"
            readonly property color contrast: "#F4F5F7"
            readonly property color muted: Qt.tint(lightTheme.background.main, Qt.alpha(main, dimOpacity))
            readonly property real dimOpacity: 0.7
            readonly property real disabledOpacity: 0.4
        }
    }
}
