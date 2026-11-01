pragma Singleton

import Quickshell
import QtQuick

import qs.core as Core

Singleton {
    id: root

    readonly property QtObject fixed: QtObject {
        id: fixedColors

        readonly property color spotify: "#1DB954"
        readonly property color internalBattery: "#DAA250"
        readonly property color externalBattery: "#5088DA"
    }

    readonly property QtObject dark: QtObject {
        id: darkTheme

        readonly property QtObject background: QtObject {
            readonly property color main: "#080A0C"
            readonly property color tint1: "#101319"
            readonly property color tint2: "#181E25"
            readonly property color tint3: "#202831"
            readonly property color tint4: "#28313E"
            readonly property color highlight: darkTheme.foreground.main
            readonly property color imagePlaceholder: highlight

            readonly property real dimOpacity: 0.7
            readonly property real opacity: 0.7
            readonly property real hoverOpacity: 0.10
            readonly property real hoverOpacityStrong: 2 * hoverOpacity
            readonly property color border: Qt.alpha(highlight, hoverOpacity)

            readonly property color accent: darkTheme.foreground.accent
            readonly property color error: darkTheme.foreground.error
            readonly property color charging: darkTheme.foreground.charging
        }

        readonly property QtObject foreground: QtObject {
            readonly property color main: "#7E85B2"
            readonly property color contrast: darkTheme.background.main

            readonly property real dimOpacity: 0.85
            readonly property real disabledOpacity: 0.4
            readonly property color muted: Qt.tint(darkTheme.background.main, Qt.alpha(main, dimOpacity))

            readonly property color accent: Core.SystemPalette.seedColor("#7B2424")
            readonly property color error: "#B12F3B"
            readonly property color alert: "#B2AB7E"
            readonly property color charging: "#85B27E"
        }
    }

    readonly property QtObject light: QtObject {
        id: lightTheme

        readonly property QtObject background: QtObject {
            readonly property color main: "#F4F5F7"
            readonly property color tint1: "#E8EBEF"
            readonly property color tint2: "#DCE0E6"
            readonly property color tint3: "#D0D5DD"
            readonly property color tint4: "#C3C9D3"
            readonly property color highlight: lightTheme.foreground.main
            readonly property color imagePlaceholder: highlight

            readonly property real dimOpacity: 0.7
            readonly property real opacity: 0.95
            readonly property real hoverOpacity: 0.10
            readonly property real hoverOpacityStrong: 2 * hoverOpacity
            readonly property color border: Qt.alpha(highlight, hoverOpacity)

            readonly property color accent: lightTheme.foreground.accent
            readonly property color error: lightTheme.foreground.error
            readonly property color charging: lightTheme.foreground.charging
        }

        readonly property QtObject foreground: QtObject {
            readonly property color main: "#555D8A"
            readonly property color contrast: lightTheme.background.main

            readonly property real dimOpacity: 0.7
            readonly property real disabledOpacity: 0.4
            readonly property color muted: Qt.tint(lightTheme.background.main, Qt.alpha(main, dimOpacity))

            readonly property color accent: Core.SystemPalette.seedColor("#8F3030")
            readonly property color error: "#A62D38"
            readonly property color alert: "#918A4F"
            readonly property color charging: "#5F8F58"
        }
    }

    readonly property QtObject matugen: QtObject {
        id: matugenTheme

        // Mode-specific constants and opacities stay in the standalone palettes.
        readonly property QtObject basePalette: Core.SystemPalette.mode === "light" ? root.light : root.dark

        readonly property QtObject background: QtObject {
            readonly property color main: Core.SystemPalette.color("window_bg", matugenTheme.basePalette.background.main)
            readonly property color tint1: Core.SystemPalette.color("surface_low", matugenTheme.basePalette.background.tint1)
            readonly property color tint2: Core.SystemPalette.color("surface", matugenTheme.basePalette.background.tint2)
            readonly property color tint3: Core.SystemPalette.color("surface_high", matugenTheme.basePalette.background.tint3)
            readonly property color tint4: Core.SystemPalette.color("surface_highest", matugenTheme.basePalette.background.tint4)
            readonly property color highlight: matugenTheme.foreground.main
            readonly property color imagePlaceholder: highlight

            readonly property real dimOpacity: matugenTheme.basePalette.background.dimOpacity
            readonly property real opacity: matugenTheme.basePalette.background.opacity
            readonly property real hoverOpacity: matugenTheme.basePalette.background.hoverOpacity
            readonly property real hoverOpacityStrong: matugenTheme.basePalette.background.hoverOpacityStrong
            readonly property color border: Qt.alpha(highlight, hoverOpacity)

            readonly property color accent: matugenTheme.foreground.accent
            readonly property color error: matugenTheme.foreground.error
            readonly property color charging: matugenTheme.foreground.charging
        }

        readonly property QtObject foreground: QtObject {
            readonly property color main: Core.SystemPalette.color("scrollbar", matugenTheme.basePalette.foreground.main)
            readonly property color contrast: matugenTheme.background.main

            readonly property real dimOpacity: matugenTheme.basePalette.foreground.dimOpacity
            readonly property real disabledOpacity: matugenTheme.basePalette.foreground.disabledOpacity
            readonly property color muted: Qt.tint(matugenTheme.background.main, Qt.alpha(main, dimOpacity))

            readonly property color accent: Core.SystemPalette.color("accent_bg", matugenTheme.basePalette.foreground.accent)
            readonly property color error: matugenTheme.basePalette.foreground.error
            readonly property color alert: matugenTheme.basePalette.foreground.alert
            readonly property color charging: matugenTheme.basePalette.foreground.charging
        }
    }
}
