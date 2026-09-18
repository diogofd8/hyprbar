import QtQuick
import QtQuick.Layouts

import qs
import qs.core as Core
import qs.modules

RowLayout {
    id: root

    // Centre modules — adjacent to the centre section.
    RowLayout {
        spacing: Settings.moduleSpacing - Core.ChevronGeometry.calcCapWidth(height)

        Weather {
            Layout.fillHeight: true
        }

        CaffeineMode {
            Layout.leftMargin: -Core.ChevronGeometry.calcCapWidth(height)
            Layout.fillHeight: true
        }

        SystemControls {
            Layout.fillHeight: true
        }

        Brightness {
            Layout.fillHeight: true
        }

        NotificationCenter {
            Layout.leftMargin: -Core.ChevronGeometry.calcCapWidth(height)
            Layout.fillHeight: true
        }
    }

    // Flexible space
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    // Right modules — adjacent to the screen edge.
    RowLayout {
        spacing: Settings.moduleSpacing - Core.ChevronGeometry.calcCapWidth(height)

        Spotify {
            Layout.rightMargin: 2 + Core.ChevronGeometry.calcCapWidth(height)
            Layout.fillHeight: true
        }

        Volume {
            Layout.rightMargin: Core.ChevronGeometry.calcCapWidth(height)
            Layout.fillHeight: true
        }

        Battery {
            Layout.fillHeight: true
        }

        PowerMenu {
            Layout.fillHeight: true
        }
    }
}
