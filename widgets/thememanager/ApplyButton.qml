import QtQuick
import QtQuick.Layouts

import qs
import qs.components
import qs.core as Core

// Bar-module style action: a label chevron led by a colour-sample hexagon.
// As in the modules, only the leading icon is the button.
Chevron {
    id: root

    property color sample: "transparent"
    property string label: "APPLY"
    readonly property alias button: iconButton
    signal clicked()

    implicitHeight: Configuration.applyHeight
    // The hexagon's point starts at this chevron's own left point. Its 120°
    // point is blunter than the chevron's, so it covers that cap completely.
    contentLeftPadding: -Core.ChevronGeometry.calcCapWidth(root.height)
    contentRightPadding: 3

    leftCap: Core.ChevronGeometry.Cap.Point
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.background.tint2
    opacity: root.enabled ? 1 : Settings.colors.foreground.disabledOpacity

    RowLayout {
        height: root.height
        spacing: 3

        HexagonButton {
            id: iconButton
            // Full height; the width follows to keep the hexagon regular.
            implicitHeight: root.height

            bgFill: root.sample

            hoverOpacity: Settings.colors.background.hoverOpacityStrong
            glyph: Configuration.applyIcon
            glyphSize: Configuration.smallGlyphSize
            glyphColor: Core.Oklch.contrastInk(root.sample)
            Accessible.role: Accessible.Button
            Accessible.name: root.label

            onLeftClicked: root.clicked()
        }

        Item {
            Layout.fillHeight: true
            implicitWidth: labelText.implicitWidth

            Text {
                id: labelText
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Settings.inducedVerticalOffset

                text: root.label
                color: Settings.colors.foreground.main
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize
                font.weight: Font.Bold
            }
        }
    }
}
