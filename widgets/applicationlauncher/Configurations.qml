pragma Singleton

import Quickshell

Singleton {
    readonly property real appLauncherWidth: 480
    readonly property real appLauncherEdgeMargin: 0
    readonly property real appLauncherBottomPadding: 12
    readonly property real appLauncherTopPadding: 8
    readonly property real appLauncherPaddingY: 8

    readonly property real launcherContainerVSpacing: 12
    readonly property real launcherContentHSpacing: 8
    readonly property real applicationListVSpacing: 2
    readonly property real listEntryHSpacing: 8
    readonly property real listEntryMetaVSpacing: 1
    readonly property real inputBarHSpacing: 4

    readonly property real inputBarIconSz: 18
    readonly property real inputBarFontSz: 13
    readonly property real inputFieldPadding: 8
    readonly property real inputFieldIconMarginS: 2
    readonly property real inputFieldIconMarginL: 8
    readonly property string inputFieldPlaceholder: "Search applications (type > for commands)"
    readonly property string commandFieldPlaceholder: "Run a command or choose an action"

    readonly property string commandInputFont: "IosevkaTerm Nerd Font Mono"
    readonly property real commandInputFontSz: 15
    readonly property string listEntryFont: "JetBrains"
    readonly property real listEntryFontSz: 14
    readonly property real listEntryDescriptionFontSz: 12
    readonly property real listEntryIconSz: 32
    readonly property real listEntryPaddingX: 6
    readonly property real listEntryPaddingY: 6
    // Blend odd-row color before the surface applies desktop transparency.
    readonly property real listEntryOddAlpha: 0.85
    readonly property int listMaxEntries: 8

    readonly property real scrollSpeed: 3
    readonly property real scrollBarWidth: 6.4
    readonly property real scrollBarButtonWidth: 8
    readonly property real scrollBarChevronHeight: 7
    readonly property real scrollBarThumbMinHeight: 12
    readonly property real scrollBarVSpacing: 0

    readonly property string applicationFallbackIcon: "application-x-executable"
    readonly property var inputBarIcons: ({
        search: "",
        command: "",
        clear: "󰅖"
    })
}
