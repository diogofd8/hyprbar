pragma Singleton

import Quickshell

Singleton {
    readonly property int widgetWidth: 1280
    readonly property int widgetHeight: 720

    readonly property real widgetPaddingX: 24
    readonly property real widgetPaddingY: 24
    readonly property real columnsHSpacing: 32
    readonly property real columnVSpacing: 12

    readonly property real entryHSeparator: 12

    readonly property real entryKeybindsHSpacing: 4
    readonly property real entryKeyMultipleHSpacing: 2
    readonly property string entryKeybindsSeparator: ""
    readonly property string entryKeyMultipleSeparator: "/"
    readonly property real entryKeyPaddingX: 4
    readonly property real entryKeyPaddingY: 2
    readonly property real entryKeyRadius: 4
    readonly property real entryKeyStrokeSz: 2
    readonly property real entryKeyFontSz: 16

    readonly property real entryLabelFontSz: 14

    readonly property var keyIcon: ({
        up: "↑",
        down: "↓",
        left: "←",
        right: "→",
        shift: "󰘶",
        tab: "⇥",
        return: "↵",
        space: "⎵",
        backspace: "⌫"
    })

    readonly property string hyprlandModKey: ""
    readonly property var hyprlandKeybinds: [
        // Hyprland
        { keybinds: [hyprlandModKey, "ALT", "Q"], label: "Exit Hyprland" },
        { keybinds: [hyprlandModKey, keyIcon.shift, "R"], label: "Reload Hyprland Config" },
        { keybinds: [hyprlandModKey, "W"], label: "Close Window" },

        // Hyprlock
        { keybinds: [hyprlandModKey, "Esc"], label: "Lock Screen" },

        // Flameshot
        { keybinds: ["PrintSc"], label: "Launch FlameShot" },

        // Hyprshot
        { keybinds: [hyprlandModKey, "PrintSc"], label: "Screenshot Region (Clipboard Only)" },
        { keybinds: [hyprlandModKey, "ALT", "PrintSc"], label: "Screenshot Region to Satty Editor" },
        { keybinds: [hyprlandModKey, "ALT", keyIcon.shift, "PrintSc"], label: "Screenshot Window" },

        // App Launchers
        { keybinds: [hyprlandModKey, keyIcon.return], label: "Open Terminal" },
        { keybinds: [hyprlandModKey, "ALT", "T"], label: "Open Alternative Terminal" },
        { keybinds: [hyprlandModKey, "E"], label: "Open File Manager" },
        { keybinds: [hyprlandModKey, keyIcon.space], label: "Open Application Menu" },
        { keybinds: [hyprlandModKey, "B"], label: "Open Web Browser" },
        { keybinds: [hyprlandModKey, "C"], label: "Open Text Editor" },
        { keybinds: [hyprlandModKey, "K"], label: "Open Clipboard Manager" },
        { keybinds: [hyprlandModKey, "Delete"], label: "Open Power Menu" },
        { keybinds: [hyprlandModKey, keyIcon.backspace], label: "Open Notification Menu" },
        { keybinds: [hyprlandModKey, "ALT", keyIcon.space], label: "Open Cheat Sheet" },

        // Tile Control - Focus
        { keybinds: [hyprlandModKey, [keyIcon.up, keyIcon.down, keyIcon.left, keyIcon.right]], label: "Move Focus" },

        // Tile Control - Position
        { keybinds: [hyprlandModKey, "ALT", [keyIcon.up, keyIcon.down, keyIcon.left, keyIcon.right]], label: "Move Window" },
        { keybinds: [hyprlandModKey, "ALT", ["PgUp", "PgDown"]], label: "Swap Window with Previous/Next" },

        // Tile Control - Window Modes
        { keybinds: [hyprlandModKey, "T"], label: "Toggle Floating State" },
        { keybinds: [hyprlandModKey, "M"], label: "Toggle Maximized State" },
        { keybinds: [hyprlandModKey, "F"], label: "Toggle Fullscreen State" },
        { keybinds: [hyprlandModKey, "ALT", "F"], label: "Set Custom Fullscreen State" },
        { keybinds: [hyprlandModKey, "P"], label: "Toggle Pseudo-Tiling Mode" },

        // Tile Control - Resize
        { keybinds: [hyprlandModKey, "CTRL", [keyIcon.up, keyIcon.down, keyIcon.left, keyIcon.right]], label: "Resize Window" },

        // Workspace Control
        { keybinds: [hyprlandModKey, ["PgUp", "PgDown"]], label: "Focus Previous/Next Workspace" },
        { keybinds: [hyprlandModKey, keyIcon.tab], label: "Focus Last Visited Workspace" },
        { keybinds: [hyprlandModKey, ["1", "2", "3", "4", "5"]], label: "Switch to numbered Workspace 1" },

        // Tile/Workspace Control - Move Active Tile
        { keybinds: [hyprlandModKey, keyIcon.shift, ["1", "2", "3", "4", "5"]], label: "Move Window to numbered Workspace" },
        { keybinds: [hyprlandModKey, keyIcon.shift, ["PgUp", "PgDown"]], label: "Move Window to Previous/Next Workspace" },

        // Mouse Actions
        { keybinds: [hyprlandModKey, "L 󰍽"], label: "Move Window with Mouse" },
        { keybinds: [hyprlandModKey, "R 󰍽"], label: "Resize Window with Mouse" }
    ]
}
