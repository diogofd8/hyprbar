pragma Singleton

import Quickshell

import qs

Singleton {
    readonly property real sliderMenuVerticalPos: 0.5
    readonly property real sliderMenuEdgeMargin: 8
    readonly property real sliderMenuPaddingX: 8
    readonly property real sliderMenuPaddingY: 4
    readonly property real sliderMenuVSpacing: -8

    readonly property real sliderEntryIconSz: 18
    readonly property real sliderEntryFontSz: 12
    readonly property real sliderEntryTrackWidth: 16
    readonly property real sliderEntryTrackHeight: 96
    readonly property real sliderEntryThumbOffsetY: 2

    readonly property real sliderMenuFadeTimerMs: 3000
    readonly property real sliderTextFadeTimerMs: 1000

    readonly property var entryIconOffset: ({
        [Settings.brightnessCtrlIcon.low]: -0.02,
        [Settings.brightnessCtrlIcon.medium]: -0.02,
        [Settings.brightnessCtrlIcon.high]: -0.02,
        [Settings.volumeCtrlIcon.off]: -0.01,
        [Settings.volumeCtrlIcon.low]: -0.21,
        [Settings.volumeCtrlIcon.medium]: 0.19,
        [Settings.volumeCtrlIcon.high]: -0.02,
        [Settings.volumeMutedIcon]: 0.09,
        [Settings.volumeHeadphoneIcon]: 0.26,
        [Settings.volumeHeadphoneMutedIcon]: -0.19
    })
}
