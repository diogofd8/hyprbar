import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.widgets as Widgets

Pane {
    id: root

    background: null
    // ────── Dimensioning ──────
    topPadding: Configuration.pagePadding - Widgets.WidgetConfiguration.dropDownWindowPadding
    bottomPadding: Configuration.pagePadding
    horizontalPadding: Configuration.pagePadding

    contentItem: ColumnLayout {
        id: pageLayout
        spacing: 0

        SystemInfoRow {
            Layout.fillWidth: true
        }

        Item {
            id: spacer
            Layout.fillHeight: true
        }

        MprisPlayer {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
