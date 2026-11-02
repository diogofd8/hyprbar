import QtQuick
import QtQuick.Layouts

import qs
import qs.core as Core
import qs.components
import qs.widgets

// LIGHT and DARK label chevrons around an icon chevron showing the active mode.
// The parent sets the height (Layout.fillHeight); every chevron follows it.
Item {
    id: root

    property string mode: "dark"
    // Text width inside each label button; the wider label by default, so both match.
    property real buttonWidth: Configuration.themeSwitchBtnPaddingX + Math.max(lightLabel.implicitWidth, darkLabel.implicitWidth)
    signal modeRequested(string mode)

    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }
    implicitWidth: chevrons.implicitWidth

    component ModeLabel: Glyph {
        required property bool active
        color: active ? Settings.colors.foreground.accent : Settings.colors.foreground.main
        iconSize: Configuration.themeSwitchIconSz
        verticalOffset: 0
    }

    Row {
        id: chevrons
        height: root.height
        // Each point nests into its neighbour's notch, leaving a small gap.
        spacing: Configuration.themeSwitchChevronSpacing - Core.ChevronGeometry.calcCapWidth(root.height)

        ChevronButton {
            objectName: "lightModeButton"
            anchors.verticalCenter: parent.verticalCenter
            height: lightLabel.implicitHeight + Configuration.themeSwitchBtnPaddingY

            leftCap: Core.ChevronGeometry.Cap.Point
            rightCap: Core.ChevronGeometry.Cap.Notch

            bgFill: root.mode === "light" ? Settings.colors.background.tint2 : Settings.colors.background.tint3
            Accessible.role: Accessible.RadioButton
            Accessible.name: "Light theme"
            Accessible.checked: root.mode === "light"

            onLeftClicked: root.modeRequested("light")

            ModeLabel {
                id: lightLabel
                width: root.buttonWidth
                icon: Configuration.lightIcon
                active: root.mode === "light"
            }
        }

        Chevron {
            height: root.height
            contentLeftPadding: Configuration.themeSwitchLabelPaddingX
            contentRightPadding: Configuration.themeSwitchLabelPaddingX

            leftCap: Core.ChevronGeometry.Cap.Point
            rightCap: Core.ChevronGeometry.Cap.Point

            bgFill: Settings.colors.background.accent

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Settings.inducedVerticalOffset
                horizontalAlignment: Text.AlignHCenter

                text: root.mode === "light"? "LIGHT" : "DARK"
                color: Settings.colors.foreground.contrast
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize
                font.weight: Font.Bold
            }
        }

        ChevronButton {
            objectName: "darkModeButton"
            anchors.verticalCenter: parent.verticalCenter
            height: darkLabel.implicitHeight + Configuration.themeSwitchBtnPaddingY

            leftCap: Core.ChevronGeometry.Cap.Notch
            rightCap: Core.ChevronGeometry.Cap.Point

            bgFill: root.mode === "dark" ? Settings.colors.background.tint2 : Settings.colors.background.tint3
            Accessible.role: Accessible.RadioButton
            Accessible.name: "Dark theme"
            Accessible.checked: root.mode === "dark"

            onLeftClicked: root.modeRequested("dark")

            ModeLabel {
                id: darkLabel
                width: root.buttonWidth
                icon: Configuration.darkIcon
                active: root.mode === "dark"
            }
        }
    }
}
