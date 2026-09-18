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
            contentLeftPadding: 6
            contentRightPadding: 6

            icon: Core.SystemUpdate.icon
            iconColor: {
                switch (Core.SystemUpdate.state) {
                case "available":
                    return Settings.colors.accentAlert
                case "error":
                    return Settings.colors.accentError
                default:
                    return Settings.colors.fgMain
                }
            }
            useMetrics: true

            onLeftClicked: Core.Actions.sysUpdateCheck()
            onRightClicked: Core.Actions.sysUpdate()
        }

        GlyphButton {
            contentLeftPadding: 5
            contentRightPadding: 5

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
