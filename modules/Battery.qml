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
                    color: Core.Helpers.batteryStatusColor(Core.PowerSupply.internal)

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
                    color: Core.Helpers.batteryStatusColor(Core.PowerSupply.external)

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
        value: powerManager.contentActive
    }

    DropDown {
        id: powerManager
        anchorItem: root

        PowerManager {
            anchors.fill: parent
        }
    }
}
