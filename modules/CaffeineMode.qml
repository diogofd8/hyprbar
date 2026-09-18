import QtQuick

import qs
import qs.components
import qs.core as Core

ChevronButton {
    height: root.height
    contentLeftPadding: 5
    contentRightPadding: 1

    leftCap: Core.ChevronGeometry.Cap.Notch
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.bgTint3
    hoverOpacity: 2 * Settings.colors.hoverOpacity

    onLeftClicked: Core.Caffeine.toggle()

    Glyph {
        icon: Core.Caffeine.enabled
            ? Settings.caffeineModeOnIcon
            : Settings.caffeineModeOffIcon
    }
}
