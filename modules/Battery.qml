import QtQuick

import qs
import qs.components
import qs.widgets
import qs.core as Core

Chevron {
    id: root
    contentLeftPadding: -Core.ChevronGeometry.calcCapWidth(height)
    contentRightPadding: 0

    leftCap: Core.ChevronGeometry.Cap.Flat
    rightCap: Core.ChevronGeometry.Cap.Notch

    bgFill: Settings.colors.bgTint1

    // PowerSupply hands over a state; turning that into a colour is the only
    // battery logic that belongs in the view. Charging wins over level, so a
    // pack topping up from 5% reads as charging rather than as an alert.
    function levelColor(battery) {
        if (battery.charging)
            return Settings.colors.accentCharging

        switch (battery.state) {
        case "empty":
            return Settings.colors.accentError
        case "alert":
            return Settings.colors.accentAlert
        default:
            return Settings.colors.fgMain
        }
    }

    Row {
        Row {
            spacing: -Core.ChevronGeometry.calcCapWidth(height)

            ChevronButton {
                height: root.height
                contentLeftPadding: 2
                contentRightPadding: 2

                leftCap: Core.ChevronGeometry.Cap.Point
                rightCap: Core.ChevronGeometry.Cap.Point

                bgFill: Settings.colors.bgTint2

                onLeftClicked: powerManager.toggle()

                Glyph {
                    text: Core.PowerSupply.internal.icon
                    color: root.levelColor(Core.PowerSupply.internal)

                    NotificationDot {
                        visible: Core.PowerSupply.internal.active
                        dotColor: Settings.colors.internalBatteryColor
                        dotBgColor: Settings.colors.bgTint2
                    }
                }
            }

            ChevronButton {
                height: root.height
                contentLeftPadding: 4
                contentRightPadding: 2

                leftCap: Core.ChevronGeometry.Cap.Notch
                rightCap: Core.ChevronGeometry.Cap.Point

                bgFill: Settings.colors.bgTint3

                onLeftClicked: powerManager.toggle()

                Glyph {
                    text: Core.PowerSupply.external.icon
                    color: root.levelColor(Core.PowerSupply.external)

                    NotificationDot {
                        visible: Core.PowerSupply.external.active
                        dotColor: Settings.colors.externalBatteryColor
                        dotBgColor: Settings.colors.bgTint3
                    }
                }
            }
        }

        Chevron {
            height: root.height
            contentLeftPadding: 3
            contentRightPadding: 3

            leftCap: Core.ChevronGeometry.Cap.Flat
            rightCap: Core.ChevronGeometry.Cap.Flat

            bgFill: Settings.colors.bgTint1

            Percentage {
                height: root.height
                value: Core.PowerSupply.active.value
            }
        }
    }

    Binding {
        target: Core.PowerSupply
        property: "discoveryActive"
        value: powerManager.isOpen
    }

    DropDown {
        id: powerManager
        anchorItem: root

        PowerManager {
            anchors.fill: parent

            onDismissRequested: powerManager.close()
        }
    }
}
