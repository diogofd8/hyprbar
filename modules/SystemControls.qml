import QtQuick

import qs
import qs.components
import qs.core as Core

Chevron {
    height: root.height
    contentLeftPadding: 0
    contentRightPadding: 0

    leftCap: Core.ChevronGeometry.Cap.Notch
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.bgTint3

    Row {
        spacing: 3

        GlyphButton {
            contentLeftPadding: 4
            contentRightPadding: 4

            icon: Settings.clipboardIcon
            useMetrics: false

            onLeftClicked: Core.Actions.clipse()
        }

        GlyphButton {
            contentLeftPadding: 4
            contentRightPadding: 4

            icon: Settings.updateNotifierIcon[1]
            useMetrics: false

            onLeftClicked: Core.Actions.sysUpdate()
        }

        GlyphButton {
            contentLeftPadding: 4
            contentRightPadding: 4

            icon: Core.Connectivity.bluetoothIcon
            useMetrics: true

            onLeftClicked: Core.Connectivity.toggleBluetooth()
            onRightClicked: Core.Actions.bluetoothManager()
        }

        GlyphButton {
            contentLeftPadding: 4
            contentRightPadding: 4

            icon: Core.Connectivity.wifiIcon
            useMetrics: false

            onLeftClicked: Core.Connectivity.toggleWifi()
            onRightClicked: Core.Actions.networkManager()
        }
    }
}
