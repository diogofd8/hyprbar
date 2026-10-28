import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs
import qs.components
import "hyprcheatsheet" as CheatSheetUI

PanelWindow {
    id: root

    readonly property Item backgroundTarget: panelBackground.paintTarget
    signal dismissed()

    WlrLayershell.namespace: "hyprbar-hyprcheatsheet"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    // With no edge anchors, the compositor centers the window on its screen.
    implicitWidth: CheatSheetUI.Configuration.widgetWidth
    implicitHeight: CheatSheetUI.Configuration.widgetHeight
    color: "transparent"

    BackgroundSurface {
        id: panelBackground
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: Settings.colors.background.main
        }
    }

    HyprlandFocusGrab {
        active: root.visible && root.backingWindowVisible
        windows: [root]
        onCleared: root.dismissed()
    }

    Controls.Pane {
        anchors.fill: parent
        focus: true
        horizontalPadding: CheatSheetUI.Configuration.widgetPaddingX
        verticalPadding: CheatSheetUI.Configuration.widgetPaddingY
        background: null
        Keys.onEscapePressed: root.dismissed()

        contentItem: RowLayout {
            id: entryColumns

            spacing: CheatSheetUI.Configuration.columnsHSpacing
            uniformCellSizes: true

            Repeater {
                model: 2

                ColumnLayout {
                    id: entryColumn

                    required property int index
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: CheatSheetUI.Configuration.columnVSpacing

                    Repeater {
                        model: root.entriesForColumn(entryColumn.index)

                        CheatSheetUI.HyprCheatSheetEntry {
                            required property var modelData

                            Layout.fillWidth: true
                            keybinds: modelData.keybinds
                            label: modelData.label
                        }
                    }
                }
            }
        }
    }

    // ────── Helper Functions ──────
    function entriesForColumn(index: int): var {
        const bindings = CheatSheetUI.Configuration.hyprlandKeybinds
        const count = Math.ceil(bindings.length / 2)
        return bindings.slice(index * count, (index + 1) * count)
    }
}
