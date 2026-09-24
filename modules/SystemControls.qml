import QtQuick

import qs
import qs.components
import qs.core as Core
import qs.widgets

Chevron {
    height: root.height
    contentLeftPadding: 0
    contentRightPadding: 1

    leftCap: Core.ChevronGeometry.Cap.Notch
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.bgTint3

    Row {
        spacing: 3

        GlyphButton {
            contentLeftPadding: 5
            contentRightPadding: 5

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

            icon: Core.Bluetooth.bluetoothIcon
            useMetrics: true

            onLeftClicked: Core.Bluetooth.toggleBluetooth()
            onRightClicked: Core.Actions.bluetoothManager()
        }

        GlyphButton {
            id: network

            contentLeftPadding: 5
            contentRightPadding: 5

            icon: Core.Network.icon
            useMetrics: true

            onLeftClicked: dropdown.toggle()
            onRightClicked: Core.Actions.networkManager()

            // The DropDown content is lazy, so its persistent parent owns scan
            // demand. Closing the menu immediately releases the Wi-Fi scanner.
            Binding {
                target: Core.Network
                property: "discoveryActive"
                value: dropdown.isOpen
            }

            DropDown {
                id: dropdown

                // ChevronButton hands its children to the Chevron's content row, so
                // the popup has to be pointed back at the button itself.
                anchorItem: network

                NetworkManager {
                    id: networkManager
                    anchors.fill: parent

                    onDismissRequested: dropdown.close()
                }
            }
        }
    }
}
