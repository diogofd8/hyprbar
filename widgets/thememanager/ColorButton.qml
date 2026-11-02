import QtQuick

import qs
import qs.components
import qs.core as Core

// Opaque saved-colour swatch. The parent owns selection; a click requests it.
HexagonButton {
    id: root

    property color sample: "transparent"
    property bool selected: false
    property string text: ""
    readonly property bool hoverOrFocus: enabled && (hovered || activeFocus)
    readonly property color checkFill: Settings.theme === "light" ? Configuration.savedColorCheckFillLight : Configuration.savedColorCheckFillDark

    // Keep the existing native-Button-style call site. HexagonButton already
    // owns left/right pointer handling and matches its hit area to the shape.
    signal clicked()
    onLeftClicked: root.clicked()

    implicitHeight: Configuration.colorBtnSz
    implicitWidth: implicitHeight * 2 / Math.sqrt(3)
    // The root is the anchor target too. Keep its fractional centre so the
    // inner and outer hexagons align with the base at non-integer widths.
    anchors.alignWhenCentered: false
    paintInForeground: true
    scrollEnabled: false
    bgFill: root.sample
    hoverOpacity: 0
    glyphColor: Core.Oklch.contrastInk(root.checkFill)
    glyphSize: Configuration.btnsIconSz
    activeFocusOnTab: true
    scale: hoverOrFocus ? Configuration.savedColorHoverScale : 1
    opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.checkable: true
    Accessible.checked: selected
    Accessible.onPressAction: root.leftClicked()

    Behavior on scale { Anim { duration: Motion.fastMs } }

    Hexagon {
        id: outlineHex
        z: -1
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        height: root.height + Configuration.savedColorBtnHoverBorder
        width: regularWidth
        visible: root.hoverOrFocus
        opacity: Settings.colors.background.hoverOpacityStrong
        fillColor: root.checkFill
        backgroundScope.target: null
    }

    Hexagon {
        id: inlineHex
        z: 1
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        height: Configuration.savedColorCheckHeight
        width: regularWidth
        visible: root.selected
        fillColor: "transparent"
        outlineColor: root.checkFill
        outlineWidth: Configuration.savedColorCheckBorderSz
        backgroundScope.target: null
        backgroundScope.paintZOffset: -1

        Glyph {
            id: checkGlyph
            z: 1
            x: parent.width / 2 - checkMetrics.tightBoundingRect.x - checkMetrics.tightBoundingRect.width / 2
            icon: Configuration.selectedIcon
            iconSize: root.glyphSize
            iconColor: root.checkFill
            verticalOffset: 0
            useMetrics: false
        }

        TextMetrics {
            id: checkMetrics
            font: checkGlyph.font
            text: checkGlyph.icon
        }
    }

    Keys.onSpacePressed: root.leftClicked()
    Keys.onReturnPressed: root.leftClicked()
}
