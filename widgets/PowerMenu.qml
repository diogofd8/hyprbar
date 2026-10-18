import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs
import qs.components
import "powermenu" as PowerMenuUI

// Loaded only while open. Keep desktop dimming off the menu's blurred surface.
PanelWindow {
    id: root

    readonly property Item backgroundTarget: menuBackground.paintTarget

    property real verticalPosition: PowerMenuUI.Configuration.powerMenuEdgeVerticalPos
    property real dimOpacity: PowerMenuUI.Configuration.powerMenuDimOpacity
    readonly property alias panelItem: panel
    property string confirmingAction: ""
    property real reveal: 0

    signal dismissed()
    signal actionConfirmed(string action)

    WlrLayershell.namespace: "hyprbar-powermenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    PanelWindow {
        id: dimmerWindow

        screen: root.screen
        visible: root.visible && root.dimOpacity > 0
        WlrLayershell.namespace: "hyprbar-powermenu-dimmer"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        color: Qt.rgba(0, 0, 0, root.dimOpacity * root.reveal)
    }

    Component.onCompleted: root.reveal = 1
    Behavior on reveal {
        Anim {
            duration: Motion.popoutOpenMs
            easing.bezierCurve: Motion.enterCurve
        }
    }

    function toggleConfirm(action: string): void {
        root.confirmingAction = root.confirmingAction === action ? "" : action
    }

    function cancelConfirm(): void {
        root.confirmingAction = ""
        canvas.forceActiveFocus()
    }

    function dismissOrCancel(): void {
        if (root.confirmingAction)
            root.cancelConfirm()
        else
            root.dismissed()
    }

    FocusScope {
        id: canvas

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: event => {
            root.dismissOrCancel()
            event.accepted = true
        }

        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Up && event.key !== Qt.Key_Down)
                return
            const count = entries.count
            if (!count)
                return
            let current = -1
            for (let i = 0; i < count; ++i) {
                if (entries.itemAt(i).activeFocus) {
                    current = i
                    break
                }
            }
            const next = current < 0 ? (event.key === Qt.Key_Down ? 0 : count - 1)
                : (current + (event.key === Qt.Key_Down ? 1 : -1) + count) % count
            entries.itemAt(next).forceActiveFocus()
            event.accepted = true
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.dismissOrCancel()
        }

        Item {
            id: panel

            BackgroundSurface {
                id: menuBackground
                anchors.fill: parent
                z: -1
            }

            width: menuEntries.implicitWidth + 2 * PowerMenuUI.Configuration.powerMenuPadding
            height: menuEntries.implicitHeight + 2 * PowerMenuUI.Configuration.powerMenuPadding
            x: parent.width - width - PowerMenuUI.Configuration.powerMenuEdgeMargin
                + (1 - root.reveal) * (width + PowerMenuUI.Configuration.powerMenuEdgeMargin)
            y: Math.max(PowerMenuUI.Configuration.powerMenuEdgeMargin,
                Math.min(parent.height - height - PowerMenuUI.Configuration.powerMenuEdgeMargin,
                    parent.height * Math.max(0, Math.min(1, root.verticalPosition)) - height / 2))
            opacity: root.reveal

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: mouse => mouse.accepted = true
            }

            ColumnLayout {
                id: menuEntries

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: PowerMenuUI.Configuration.powerMenuPadding
                spacing: PowerMenuUI.Configuration.powerActionsVSpacing

                Repeater {
                    id: entries

                    model: PowerMenuUI.Configuration.powerActionEntries

                    PowerMenuUI.PowerMenuEntry {
                        id: entry
                        required property var modelData

                        Layout.alignment: Qt.AlignRight
                        Layout.fillWidth: false
                        name: modelData.name
                        icon: modelData.icon
                        confirmOpen: root.confirmingAction === modelData.action
                        onClicked: {
                            entry.forceActiveFocus()
                            root.toggleConfirm(modelData.action)
                        }
                        onConfirmed: root.actionConfirmed(modelData.action)
                        onCancelled: root.cancelConfirm()
                    }
                }
            }
        }
    }
}
