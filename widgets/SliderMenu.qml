import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import Quickshell
import Quickshell.Wayland

import qs
import qs.components
import qs.core as Core
import "slidermenu" as SliderMenuUI

PanelWindow {
    id: root

    readonly property Item backgroundTarget: menuBackground.paintTarget

    property string activeControl: "volume"
    readonly property bool interacting: hover.hovered || volumeEntry.interacting || brightnessEntry.interacting

    signal dismissed()

    WlrLayershell.namespace: "hyprbar-slidermenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { left: true; top: true }

    margins.left: SliderMenuUI.Configuration.sliderMenuEdgeMargin
    margins.top: root.menuTop()

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    function show(control: string): void {
        root.activeControl = control
        if (control === "volume")
            volumeEntry.revealValue()
        else if (control === "brightness")
            brightnessEntry.revealValue()
        if (!root.interacting)
            dismissTimer.restart()
    }

    function menuTop(): real {
        const edge = SliderMenuUI.Configuration.sliderMenuEdgeMargin
        const position = Math.max(0, Math.min(1, SliderMenuUI.Configuration.sliderMenuVerticalPos))
        return Math.round(Math.max(edge,
            Math.min(root.screen.height - root.height - edge,
                root.screen.height * position - root.height / 2)))
    }

    Timer {
        id: dismissTimer

        interval: SliderMenuUI.Configuration.sliderMenuFadeTimerMs
        running: !root.interacting
        onTriggered: root.dismissed()
    }

    Controls.Pane {
        id: panel
        anchors.fill: parent
        horizontalPadding: SliderMenuUI.Configuration.sliderMenuPaddingX
        verticalPadding: SliderMenuUI.Configuration.sliderMenuPaddingY

        HoverHandler {
            id: hover
            parent: panel
        }

        background: BackgroundSurface {
            id: menuBackground
            anchors.alignWhenCentered: false

            Chevron {
                id: backgroundChevron
                anchors.centerIn: parent
                anchors.alignWhenCentered: false
                width: parent.height
                height: parent.width
                rotation: 90

                leftCap: Core.ChevronGeometry.Cap.Point
                rightCap: Core.ChevronGeometry.Cap.Point
                bgFill: Settings.colors.background.main
            }
        }

        contentItem: ColumnLayout {
            id: menuColumn
            spacing: SliderMenuUI.Configuration.sliderMenuVSpacing

            SliderMenuUI.SliderEntry {
                id: volumeEntry

                Layout.fillWidth: true
                icon: Core.Audio.sink.icon
                value: Core.Audio.sink.value
                available: Core.Audio.sink.available
                selected: root.activeControl === "volume"
                onValueRequested: value => Core.Audio.setVolume(value)

                parentBg: backgroundChevron.bgFill
            }

            SliderMenuUI.SliderEntry {
                id: brightnessEntry

                Layout.fillWidth: true
                icon: Core.Backlight.icon
                value: Core.Backlight.value
                available: Core.Backlight.available
                selected: root.activeControl === "brightness"
                onValueRequested: value => Core.Backlight.setBrightness(value)

                parentBg: backgroundChevron.bgFill
            }
        }
    }
}
