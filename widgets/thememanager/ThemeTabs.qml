import QtQuick
import QtQuick.Layouts

import qs
import qs.components
import qs.widgets

// Hexagonal buttons joined by a bar from the first centre to the last.
Item {
    id: root

    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }
    default property alias buttons: row.data

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    BackgroundRectangle {
        z: -1
        anchors.fill: parent
        anchors.leftMargin: row.children.length ? row.children[0].width / 2 : 0
        anchors.rightMargin: row.children.length ? row.children[row.children.length - 1].width / 2 : 0
        color: Settings.colors.background.tint2
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: WidgetConfiguration.hexBtnSpacing
    }
}
