pragma Singleton

import Quickshell

Singleton {
    // ────── General ──────
    readonly property int widgetBoxPadding: 8

    readonly property int topBarPadding: 6
    readonly property int mainColumnGap: 12
    readonly property int sectionSpacing: 16

    readonly property real mainButtonSize: 18
    readonly property real secondaryButtonSize: 16
    readonly property real columnLabelFontSize: 11
    readonly property real subTextFontSize: 11
    readonly property real btNameFontSize: 12
    readonly property int transitionMs: 100

    // ------- Blueman Entries -------
    readonly property int btEntryRowSpacing: 3
    readonly property int btEntryExpandedRowSpacing: 0
    readonly property int btEntryPadding: 3
    readonly property int btScanningIconSpacing: 2

    // Remembered devices past this count stay hidden behind showAllBtn.
    readonly property int pairedVisibleMax: 5

    // ────── Icons ──────
    readonly property var btEntryMapping: [
        { icon: "󰂰", device: "audio-card" },
        { icon: "󰋋", device: "audio-headphones" },
        { icon: "󰋎", device: "audio-headset" },
        { icon: "󰄀", device: "camera-photo" },
        { icon: "󰕧", device: "camera-video" },
        { icon: "󰍹", device: "computer" },
        { icon: "󰊗", device: "input-gaming" },
        { icon: "󰌌", device: "input-keyboard" },
        { icon: "󰍽", device: "input-mouse" },
        { icon: "󰓶", device: "input-tablet" },
        { icon: "󰣕", device: "modem" },
        { icon: "󰎈", device: "multimedia-player" },
        { icon: "󰖩", device: "network-wireless" },
        { icon: "󰏲", device: "phone" },
        { icon: "󰐪", device: "printer" },
        { icon: "󰚫", device: "scanner" },
        { icon: "󰍹", device: "video-display" },
        { icon: "󰂯", device: "unknown" }
    ]

    readonly property string bmLauncherIcon: ""
    readonly property string bmInitScanIcon: "󱉶"
    readonly property string bmStopScanIcon: "󰓛"
    readonly property string bmIsScanningIcon: "󰑥"
    readonly property string bmClearScanIcon: "󰃢"
    readonly property string bmBluetoothIcon: "󰂯"
    readonly property string btEditConnectionIcon: ""
    readonly property string btPairIcon: "󰌷"
    readonly property string btForgetIcon: "󰩹"
    readonly property string btCancelIcon: "󰜺"
    readonly property string btConnectIcon: ""
    readonly property string btDisconnectIcon: ""
    readonly property string btExpandIcon: ""
    readonly property string btSendIcon: "󰒊"
    readonly property string btDismissIcon: "󰅖"

    readonly property int contentWidth: 250
    readonly property int listMaxHeight: 440
}
