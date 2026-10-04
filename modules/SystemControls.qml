import QtQuick

import qs
import qs.components
import qs.core as Core
import qs.widgets

Chevron {
    id: root

    height: root.implicitHeight
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
            id: bluetooth

            contentLeftPadding: 5
            contentRightPadding: 5

            icon: Core.Bluetooth.bluetoothIcon
            useMetrics: true

            onLeftClicked: btManager.toggle()
            onRightClicked: Core.Actions.bluetoothManager()

            Binding {
                target: Core.Bluetooth
                property: "discoveryActive"
                value: btManager.contentActive
            }

            DropDown {
                id: btManager
                anchorItem: bluetooth

                // The system Bluetooth agent owns the pairing prompt, and its
                // window takes focus. Stay open so the row being paired does
                // not vanish out from under the user mid-handshake.
                holdOpen: Core.Bluetooth.pairingInFlight

                BluetoothManager {
                    id: bluetoothManager
                    anchors.fill: parent

                    onDismissRequested: btManager.close()
                }
            }
        }

        GlyphButton {
            id: network

            contentLeftPadding: 5
            contentRightPadding: 5

            icon: Core.Network.icon
            useMetrics: true

            onLeftClicked: nwManager.toggle()
            onRightClicked: Core.Actions.networkManager()

            // Keep scan data until the closing popup has finished revealing it.
            // The host releases the loaded content after the exit animation.
            Binding {
                target: Core.Network
                property: "discoveryActive"
                value: nwManager.contentActive
            }

            DropDown {
                id: nwManager
                wantsKeyboardFocus: Core.Network.passwordPromptActive

                // ChevronButton hands its children to the Chevron's content row, so
                // the popup has to be pointed back at the button itself.
                anchorItem: network

                NetworkManager {
                    id: networkManager
                    anchors.fill: parent

                    onDismissRequested: nwManager.close()
                }
            }
        }
    }
}
