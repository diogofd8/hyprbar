import QtQuick
import Quickshell

import qs
import qs.components
import qs.core as Core

Chevron {
    contentLeftPadding: 0
    contentRightPadding: 0

    leftCap: Core.ChevronGeometry.Cap.Point
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.accentMain

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Text {
        text: Qt.formatDateTime(clock.date, "HH:mm:ss")
        color: Settings.colors.fgDark
        font.family: Settings.labelFontFamily
        font.weight: Font.Bold
        font.pixelSize: Settings.labelFontSize

        y: Settings.inducedVerticalOffset
    }
}
