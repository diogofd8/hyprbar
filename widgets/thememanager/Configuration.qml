pragma Singleton

import Quickshell
import qs.widgets

Singleton {
    // ────── General Dimensioning ──────
    readonly property real themePageHeaderMarginY: 8
    readonly property real themePageHeaderMarginX: 8
    readonly property real themePageMarginX: 12
    readonly property real themePagePaddingY: 32

    readonly property real applyBtnPaddingX: 3
    readonly property real applyBtnPaddingY: 3
    readonly property real applyBtnHSpacing: 6
    readonly property real btnsIconSz: 13

    // ────── Oxidye Mode ──────
    readonly property real themeSwitchBtnPaddingX: 10
    readonly property real themeSwitchBtnPaddingY: 3
    readonly property real themeSwitchIconSz: 13
    readonly property real themeSwitchLabelPaddingX: 2
    readonly property real themeSwitchChevronSpacing: 5

    readonly property real pickerContainerBorderSz: 1
    readonly property real colorSelectorVSpacing: 12
    readonly property real colorSelectorHSpacing: 12
    readonly property real colorSelectorPaddingX: 32
    readonly property real colorSelectorPaddingY: 32
    readonly property real savedColorsPaddingY: 12
    readonly property real savedColorsSeparatorPaddingLeft: 5
    readonly property real savedColorsSeparatorPaddingRight: 8

    readonly property real colorBtnSz: 22
    readonly property real savedColorBtnHeight: 22
    readonly property real savedColorBtnHoverBorder: 2
    readonly property real savedColorHoverScale: 1.1
    readonly property real savedColorCheckHeight: 18
    readonly property real savedColorCheckBorderSz: 2
    readonly property string savedColorCheckFillLight: "#000000"
    readonly property string savedColorCheckFillDark: "#FFFFFF"
    readonly property real addColorBorderSz: 2

    readonly property string oxidyeExecutable: Quickshell.env("HOME") + "/.local/bin/oxidye"
    // Optional complete OKLCH seeds; UI saves stay in the existing XDG state file.
    readonly property var savedSpectra: [
        "oklch(0.397 0.121 24.5)" // #7B2424
    ]

    readonly property var pageIcons: ["", "󱥚"]
    readonly property string savedColorsIcon: ""
    readonly property string lightIcon: ""
    readonly property string darkIcon: ""
    readonly property string applyIcon: "󰄬"
    readonly property string selectedIcon: "󰄬"
    readonly property string saveIcon: ""

    // ────── Matugen Mode ──────
    readonly property string wallpaperDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers/"
    readonly property real navigationBtnsPaddingY: 12
    readonly property real navigationBtnsPaddingX: 2
    readonly property real navigationBtnWeakMarginSz: 7
    readonly property real navigationBtnsSz: 12

    readonly property real navigationContextHSpacing: 4
    readonly property real imagePreviewHSpacing: 4

    readonly property real imagePreviewVSpacing: 2
    readonly property real imagePreviewMainWidth: 240
    readonly property real imagePreviewSecWidth: 160
    readonly property real imagePreviewRadius: 12
    readonly property real imagePreviewLabelFontSz: 10

    readonly property var navigationIcon: ["", ""]
}
