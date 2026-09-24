pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // ────── Theme Selection ──────
    PersistentProperties {
        id: persist
        property string theme: "dark"
    }

    readonly property string theme: persist.theme
    readonly property QtObject colors: {
        switch (persist.theme) {
            case "light": return Theme.light;
            case "dark": // passthrough
            default: return Theme.dark;
        }
    }

    function setTheme(value: string): void {
        persist.theme = value;
    }

    // ────── Wlr Layer Shell ──────
    readonly property string wlrLayerShellNamespace: "hyprbar"

    // ────── Bar Dimensions ──────
    readonly property int barHeight: 28

    readonly property int barPaddingTop: 2
    readonly property int barPaddingBottom: 2
    readonly property int barPaddingRight: 10
    readonly property int barPaddingLeft: 10
    readonly property real transparentBgPercent: 0.5
    readonly property int dropDownPadding: 4
    readonly property int dropDownTransitionMs: 120
    readonly property real dropDownTransitionOffset: 10

    readonly property real chevronAngle: 105
    readonly property int moduleSpacing: 6
    readonly property int buttonClickableArea: 34
    readonly property real inducedVerticalOffset: 0.5

    // ────── Input Rules ──────
    readonly property int actionScrollDelta: 25
    readonly property var popupCloseKeys: [Qt.Key_Escape, Qt.Key_Q]

    // ────── Typography ──────
    readonly property string labelFontFamily: "JetBrains Mono"
    readonly property int labelFontSize: 14
    readonly property int smallCapsFontSize: 11
    readonly property string iconFontFamily: "IosevkaTerm Nerd Font Propo"
    readonly property int iconFontSize: 16
    readonly property int buttonFontSize: 20

    // ────── Workspace pips ──────
    readonly property int minWorkspaceCount: 5  // from Hyprland Lua Config
    readonly property int workspaceSpacing: 8
    readonly property int workspaceIconSize: 14
    readonly property int activeWorkspaceIconSize: 20
    readonly property real workspaceHoverOpacity: 0.10

    // ────── Icons ──────
    readonly property var launcherIcon: "󰣇"
    readonly property var powerMenuIcon: "󰐥"
    readonly property var activeWorkspaceIcon: ""
    readonly property var defaultWorkspaceIcon: ""
    readonly property var emptyWorkspaceIcon: ""
    readonly property var urgentWorkspaceIcon: ""
    readonly property var ramStressIcon: "󰘚"
    readonly property var cpuStressIcon: ""
    readonly property var cpuTempIcon:
        ["󱃃", "󰔏", "󱃂"]
    readonly property var notificationIcon: "󰂚"
    readonly property var bluetoothOffIcon: "󰂲"
    readonly property var bluetoothOnIcon: "󰂯"
    readonly property var bluetoothConnectedIcon: "󰂰"
    readonly property var networkWifiOffIcon: "󰤮"
    readonly property var networkWiFiOnIcon:
        ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    readonly property var networkWifiOpenIcon: "󰤨"
    readonly property var networkWifiProtectedIcon: "󰤪"
    readonly property var networkEthIcon: "󰈁"
    readonly property var clipboardIcon: ""
    readonly property var updateNotifierIcon:
        ["󰄴", "󱤧"]
    readonly property var updateNotifierSyncIcon: "󰓦"
    readonly property var updateNotifierErrorIcon: "󰅤"
    readonly property var brightnessCtrlIcon:
        ["󰃞", "󰃟", "󰃠"]
    readonly property var batteryCtrlIcon:
        ["󰂎", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property var batteryChargingIcon: "󰂄"
    readonly property var batteryOffIcon: "󱟩"
    readonly property var volumeCtrlIcon:
        ["", "", "", ""]
    readonly property var volumeMutedIcon: ""
    readonly property var volumeHeadphoneIcon: "󰋋"
    readonly property var volumeHeadphoneMutedIcon: "󰟎"
    readonly property var volumeInputMicOnIcon: ""
    readonly property var volumeInputMicOffIcon: ""
    readonly property var caffeineModeOnIcon: "󰈈"
    readonly property var caffeineModeOffIcon: "󰈉"

    // ────── System Statistics API Configuration ──────
    readonly property int systemStatsPollingIntervalMs: 2000
    readonly property var cpuStressThresholds: [
        {state: "idle", threshold: 0},
        {state: "low", threshold: 10},
        {state: "regular", threshold: 40},
        {state: "high", threshold: 70},
        {state: "max", threshold: 95}
    ]
    readonly property var cpuTempThresholds: [
        {state: "normal", threshold: 0},
        {state: "warning", threshold: 70},
        {state: "critical", threshold: 85}
    ]
    readonly property var ramStressThresholds: [
        {state: "low", threshold: 0},
        {state: "regular", threshold: 20},
        {state: "high", threshold: 70},
        {state: "max", threshold: 95}
    ]

    // ────── System Update API Configuration ──────
    readonly property int updateCheckIntervalMs: 3600 * 1000
    readonly property int updateCheckHeartbeatMs: 60 * 1000
    readonly property int updateCheckTimeoutS: 60
    readonly property int updateSessionPollIntervalMs: 3000

    // ────── Brightness API Configuration ──────
    readonly property int brightnessStepPercentage: 1
    readonly property int brightnessMinPercentage: 0
    readonly property var brightnessLevelThresholds: [
        {state: "low", threshold: 0},
        {state: "medium", threshold: 34},
        {state: "high", threshold: 67}
    ]

    // ────── Battery API Configuration ──────
    readonly property string internalBatteryPath: "BAT0"
    readonly property string externalBatteryPath: "BAT1"
    readonly property var batteryLevelThresholds: [
        {state: "empty", threshold: 0},
        {state: "alert", threshold: 1},
        {state: "default", threshold: 16},
        {state: "full", threshold: 98},
    ]

    // ────── Connectivity API Configuration ──────
    readonly property string networkEthInterface: "enp0s31f6"
    readonly property string networkWifiInterface: "wlp3s0"
    readonly property var wifiSignalThresholds: [
        {state: "weak", threshold: 0},
        {state: "poor", threshold: 17},
        {state: "fair", threshold: 50},
        {state: "good", threshold: 71},
        {state: "excellent", threshold: 90}
    ]

    // ────── Volume API Configuration ──────
    readonly property int volumeStepPercentage: 1
    readonly property var volumeLevelThresholds: [
        {state: "off", threshold: 0},
        {state: "low", threshold: 1},
        {state: "medium", threshold: 34},
        {state: "high", threshold: 67},
    ]
}
