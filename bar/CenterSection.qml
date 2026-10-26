import QtQuick
import QtQuick.Layouts

import qs
import qs.modules

RowLayout {
    id: root

    signal mprisRequested()

    // Centre modules
    RowLayout {
        spacing: Settings.moduleSpacing

        Clock {
            Layout.fillHeight: true
            onMprisRequested: root.mprisRequested()
        }
    }
}
