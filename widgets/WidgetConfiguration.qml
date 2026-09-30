pragma Singleton

import Quickshell

Singleton {
    // ────── General DropDown Layout Properties ──────
    readonly property real dropDownWindowPadding: 4

    readonly property real mainRowPadding: 4
    readonly property real mainRowHSpacing: 8
    readonly property real mainRowVMargin: 12

    readonly property real sectionVSpacing: 16
    readonly property real sectionContentVSpacing: 4

    readonly property int rowContentMaxHeight: 440

    // ────── Component Specific Layout Properties ──────
    readonly property real hexSwitchSpacing: 5

    readonly property real hexBtnVPadding: 1
    readonly property real hexBtnSpacing: 6

    readonly property real statusIconExtraSpacing: 2
    readonly property real sliderExtraSpacing: 4

    // ────── General Row Entry Layout Properties ──────
    readonly property real entryHPadding: 6
    readonly property real entryVPadding: 2
    readonly property real entryIconHPadding: 4

    readonly property real entryRowVSpacing: 1
    readonly property real entryTitleRowHSpacing: 2
    readonly property real entryExtendedRowHSpacing: 4

    // ────── General Font Size Properties ──────
    readonly property real widgetMainIconSz: 18
    readonly property real widgetEmbeddedIconSz: 16
    readonly property real widgetSecondaryIconSz: 16
    readonly property real widgetMainFontSz: 11
    readonly property real sectionRowLabelFontSz: 11

    readonly property real widgetMsgFieldFontSz: 11

    readonly property real entryRowTitleFontSz: 12
    readonly property real entryRowMainIconSz: 18
    readonly property real entryRowSecondaryIconSz: 16
    readonly property real entryRowDefaultFontSz: 11

    // ────── Animation Properties ──────
    readonly property int transitionMs: 100
}