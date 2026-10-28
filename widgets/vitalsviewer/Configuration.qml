pragma Singleton

import Quickshell

Singleton {
    readonly property int widgetWidth: 380
    readonly property int widgetHeight: 310

    readonly property int gaugeContainerPaddingX: 24
    readonly property int coresContainerPaddingX: 4
    readonly property int coresContainerMarginBottom: 12
    readonly property int coresContainerMarginTop: 6

    // ────── Shared Gauges ──────
    readonly property real gaugeArcGapAngle: 12
    readonly property real gaugeArcStrokeWidth: 8
    readonly property real gaugeSz: 135
    readonly property real gaugeInnerDiameterOffset: 24
    readonly property real gaugeStatsPaddingTop: 8
    readonly property real gaugeStatsPaddingBottom: 12
    readonly property real gaugeArcBackgroundOpacity: 0.4
    readonly property real gaugeLabelBottomMargin: -2
    readonly property real gaugeLabelLetterSpacing: 4
    readonly property real gaugeLabelFontSz: 14
    readonly property real gaugeMainMetricFontSz: 24
    readonly property real gaugeMainUnitFontSz: 16
    readonly property real gaugeSecondaryMetricsVSpacing: 2
    readonly property real gaugeSecondaryMetricHSpacing: 6
    readonly property real gaugeSecondaryMetricFontSz: 12
    readonly property real gaugeSecondaryMetricDotSz: 6
    readonly property real gaugeSecondaryMetricPaddingX: 8
    readonly property real gaugeSecondaryMetricPaddingY: 2

    // ────── CPU Gauge ──────
    readonly property real cpuGaugeMainUnitLetterSpacing: -2
    readonly property real cpuGaugeTemperatureMaxValue: 100

    readonly property var cpuGaugeColorHueShifts: [40, 210]

    // ────── MEM Gauge ──────
    readonly property real memGaugeMainMetricHSpacing: 5
    readonly property real memGaugeMainLetterSpacing: -4
    readonly property real memGaugeMainUnitLetterSpacing: -1
    readonly property int memGaugeMainMetricDecimals: 1

    readonly property var memGaugeColorHueShifts: [20, 230]

    // ────── Core Entries ──────
    readonly property real coreEntriesHSpacing: 0
    readonly property real coreEntriesVSpacing: 6

    // Logical thread IDs and temperature-array indices for this laptop's SMT pairs.
    readonly property var coreEntryColumns: [
        [
            { thread: 0, temperatureCore: 0 },
            { thread: 1, temperatureCore: 1 },
            { thread: 2, temperatureCore: 2 },
            { thread: 3, temperatureCore: 3 }
        ],
        [
            { thread: 4, temperatureCore: 0 },
            { thread: 5, temperatureCore: 1 },
            { thread: 6, temperatureCore: 2 },
            { thread: 7, temperatureCore: 3 }
        ]
    ]

    // ────── Core Entry ──────
    readonly property real coreEntryHSpacing: 8
    readonly property real coreEntryGaugesVSpacing: 2
    readonly property real coreEntryLabelHSpacing: 4
    readonly property real coreEntryGaugeWidth: 50
    readonly property real coreEntryGaugeStressTempRatio: 3
    readonly property real coreEntryTemperatureGaugeHeight: 3
    readonly property real coreEntryFontSz: 13

    // ────── System Info Row ──────
    readonly property real sysInfoRowHSpacing: 3
    readonly property real sysCompositeItemHSpacing: 4
    readonly property real sysProfileImgSz: 32
    readonly property real sysEntryFontSz: 13
    readonly property real sysEntryIconSz: 16

    readonly property var sysClockIcon: ""
    readonly property var sysDistroIcon: ({
        // Add the entries you need from: nf-linux-*
        arch: "",
        ubuntu: "",
        fedora: "",
        tux: ""
    })

    readonly property var sysDesktopIcon: ({
        hyprland: "",
        kde: "",
        gnome: "",
        default_shell: ""
    })

    function desktopIcon(desktopName) {
        const desktops = desktopName.toLowerCase().split(":");

        for (const desktop of desktops) {
            if (sysDesktopIcon[desktop])
                return sysDesktopIcon[desktop];
        }

        return sysDesktopIcon.default_shell;
    }
}
