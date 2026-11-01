pragma Singleton

import Quickshell

Singleton {
    readonly property int widgetWidth: 640
    readonly property string oxidyeExecutable: Quickshell.env("HOME") + "/.local/bin/oxidye"
    // Optional complete OKLCH seeds; UI saves stay in the existing XDG state file.
    readonly property var savedSpectra: []
    readonly property var pageIcons: ["󰏘", "󰸉"]
    readonly property string lightIcon: ""
    readonly property string darkIcon: ""
    readonly property string applyIcon: "󰄬"
    readonly property string saveIcon: "󰐕"
    readonly property int savedColorHeight: 16
    // Glyphs on saved-colour sized hexagons, also used by the apply chevron.
    readonly property int smallGlyphSize: savedColorHeight - 6
    readonly property int applyHeight: 24
}
