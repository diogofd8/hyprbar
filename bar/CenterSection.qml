import QtQuick
import QtQuick.Layouts

import qs
import qs.modules

RowLayout {
    id: root

    signal systemRequested()

    // Centre modules
    RowLayout {
        spacing: Settings.moduleSpacing

        Clock {
            Layout.fillHeight: true
            onSystemRequested: root.systemRequested()
        }
    }
}
