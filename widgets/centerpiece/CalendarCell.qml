import QtQuick
import QtQuick.Layouts

import qs
import qs.components

Item {
    id: root

    required property string text
    property bool heading: false
    property bool adjacentMonth: false
    property bool selected: false

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Loader {
        anchors.fill: parent
        active: root.selected
        opacity: root.adjacentMonth ? Settings.colors.disabledOpacity : 1

        sourceComponent: Hexagon {
            fillColor: Settings.colors.accentMain
        }
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        padding: Configuration.calendarCellPadding
        color: root.selected ? Settings.colors.fgDark : Settings.colors.fgMain
        opacity: root.adjacentMonth ? Settings.colors.disabledOpacity : 1
        font.family: Settings.labelFontFamily
        font.pixelSize: Configuration.calendarFontSz
        font.bold: root.heading || root.selected
    }
}
