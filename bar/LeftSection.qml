import QtQuick
import QtQuick.Layouts

import qs
import qs.core as Core
import qs.modules

RowLayout {
    id: root

    // Left modules — adjacent to the screen edge.
    RowLayout {
        spacing: Settings.moduleSpacing - Core.ChevronGeometry.calcCapWidth(height)

        Launcher {
            Layout.rightMargin: 2
            Layout.fillHeight: true
        }

        Workspaces {
            Layout.fillHeight: true
        }
    }

    // Flexible space
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    // Centre modules — adjacent to the centre section.
    RowLayout {
        spacing: Settings.moduleSpacing - Core.ChevronGeometry.calcCapWidth(height)

        Vitals {
            Layout.fillHeight: true
        }

        Date {
            Layout.fillHeight: true
        }
    }
}
