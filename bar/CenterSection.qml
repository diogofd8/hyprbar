import QtQuick
import QtQuick.Layouts

import qs
import qs.modules

RowLayout {
    id: root

    // Centre modules
    RowLayout {
        spacing: Settings.moduleSpacing

        Clock {
            Layout.fillHeight: true
        }
    }
}
