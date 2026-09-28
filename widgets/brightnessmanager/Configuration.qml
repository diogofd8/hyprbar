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
    readonly property real brNameFontSize: 12
    readonly property int transitionMs: 100

    // ------- Brightness Entries -------
    readonly property int brEntryRowSpacing: 3
    readonly property int brEntryPadding: 4
    readonly property int brScanningIconSpacing: 2

    // ------- Brightness Settings -------
    readonly property int nightTemperatureK: 4000
    readonly property int neutralTemperatureK: 6500

    // ────── Icons ──────
    readonly property string nightModeIcon: "󰥟"
    readonly property string displayEntryIcon: "󰍹"
    readonly property string keyboardEntryIcon: "󰥻"

    readonly property int contentWidth: 250
    readonly property int listMaxHeight: 440
}
