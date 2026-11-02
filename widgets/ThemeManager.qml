import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs
import qs.components
import qs.core as Core
import "thememanager" as ThemeUI

PanelWindow {
    id: root

    readonly property Item backgroundTarget: panelBackground.paintTarget
    readonly property int oxidyePage: 0
    readonly property int matugenPage: 1
    property int activePage: oxidyePage
    readonly property string feedback: {
        if (Core.ThemeControl.busy) return Core.ThemeControl.phase === "spectra" ? "Updating saved colours…" : "Applying theme…"
        return Core.ThemeControl.lastError || (activePage === matugenPage ? Core.Wallpapers.lastError : "")
            || Core.ThemeControl.spectraError || Core.SystemPalette.lastError
    }
    signal dismissed()

    Component.onCompleted: activePage = Core.SystemPalette.source === "matugen" ? matugenPage : oxidyePage

    WlrLayershell.namespace: "hyprbar-thememanager"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.ceil(panel.implicitWidth)
    implicitHeight: Math.ceil(panel.implicitHeight) + ThemeUI.Configuration.themePagePaddingY
    color: "transparent"

    BackgroundSurface {
        id: panelBackground
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent;
            color: Settings.colors.background.main
        }
    }

    HyprlandFocusGrab {
        active: root.visible && root.backingWindowVisible
        windows: [root]
        onCleared: root.dismissed()
    }

    Controls.Pane {
        id: panel
        anchors.fill: parent
        focus: true
        padding: 0
        background: null
        Keys.onEscapePressed: root.dismissed()

        contentItem: ColumnLayout {
            id: panelContent
            height: panel.height
            width: panel.width
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                spacing: ThemeUI.Configuration.themePageHeaderMarginY

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: ThemeUI.Configuration.themePageHeaderMarginY
                    Layout.leftMargin: ThemeUI.Configuration.themePageHeaderMarginX
                    Layout.rightMargin: ThemeUI.Configuration.themePageHeaderMarginX
                    spacing: 0

                    ThemeUI.ThemeTabs {
                        id: themeTabs

                        HexagonButton {
                            objectName: "oxidyePageButton"
                            bgFill: root.activePage === root.oxidyePage ? Settings.colors.background.accent : Settings.colors.background.tint3
                            glyph: ThemeUI.Configuration.pageIcons[root.oxidyePage]
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: root.activePage === root.oxidyePage ? Settings.colors.foreground.contrast : Settings.colors.foreground.main
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: "Oxidye"
                            Accessible.checked: root.activePage === root.oxidyePage
                            onLeftClicked: root.activePage = root.oxidyePage
                        }

                        HexagonButton {
                            objectName: "matugenPageButton"
                            bgFill: root.activePage === root.matugenPage ? Settings.colors.background.accent : Settings.colors.background.tint3
                            glyph: ThemeUI.Configuration.pageIcons[root.matugenPage]
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: root.activePage === root.matugenPage ? Settings.colors.foreground.contrast : Settings.colors.foreground.main
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: "Matugen"
                            Accessible.checked: root.activePage === root.matugenPage
                            onLeftClicked: root.activePage = root.matugenPage
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ThemeUI.LightDarkSwitch {
                        Layout.alignment: Qt.AlignCenter
                        height: themeTabs.implicitHeight
                        mode: Settings.theme
                        enabled: Core.ThemeControl.canToggleMode && !Core.ThemeControl.busy
                        opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity
                        onModeRequested: requested => {
                            if (requested !== Settings.theme)
                                Core.ThemeControl.toggleMode()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        id: themeManagerMode
                        spacing: WidgetConfiguration.mainRowHSpacing

                        Text {
                            text: "MODE:"
                            elide: Text.ElideRight
                            color: Settings.colors.foreground.main
                            font.family: Settings.labelFontFamily
                            font.pixelSize: WidgetConfiguration.widgetMainFontSz
                        }

                        Text {
                            objectName: "themeSourceLabel"
                            text: root.activePage === root.matugenPage ? "Matugen" : "Oxidye"
                            elide: Text.ElideRight
                            color: Settings.colors.foreground.accent
                            font.family: Settings.labelFontFamily
                            font.pixelSize: WidgetConfiguration.widgetMainFontSz
                        }
                    }
                }

                // ────── Separator ──────
                Separator {
                    Layout.fillWidth: true
                    Layout.bottomMargin: WidgetConfiguration.mainRowVMargin
                    color: Settings.colors.background.tint4
                }
            }

            Flickable {
                id: scroll
                readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: scroll }
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: implicitHeight
                implicitWidth: pages.implicitWidth
                implicitHeight: Math.min(pages.implicitHeight, WidgetConfiguration.rowContentMaxHeight)
                contentWidth: width
                contentHeight: pages.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    id: pages
                    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: pages }
                    width: scroll.width
                    height: Math.max(scroll.height, implicitHeight)
                    implicitWidth: Math.max(oxidye.implicitWidth, matugen.implicitWidth)
                    implicitHeight: Math.max(oxidye.implicitHeight, matugen.implicitHeight)
                    clip: true

                    ThemeUI.OxidyePage {
                        id: oxidye
                        width: pages.width
                        height: pages.height
                        x: (root.oxidyePage - root.activePage) * pages.width
                        enabled: root.activePage === root.oxidyePage
                        visible: x + width > 0

                        Behavior on x {
                            enabled: root.backingWindowVisible
                            Anim { easing.bezierCurve: Motion.standardCurve }
                        }
                    }

                    ThemeUI.MatugenPage {
                        id: matugen
                        active: root.visible && root.backingWindowVisible && root.activePage === root.matugenPage
                        monitorName: root.screen ? root.screen.name : ""
                        width: pages.width
                        height: pages.height
                        x: (root.matugenPage - root.activePage) * pages.width
                        enabled: root.activePage === root.matugenPage
                        visible: x < pages.width

                        Behavior on x {
                            enabled: root.backingWindowVisible
                            Anim { easing.bezierCurve: Motion.standardCurve }
                        }
                    }
                }
            }

            Text {
                objectName: "themeFeedback"
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                visible: text.length > 0
                text: root.feedback
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.family: Settings.labelFontFamily
                font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                color: Core.ThemeControl.lastError || Core.Wallpapers.lastError || Core.ThemeControl.spectraError || Core.SystemPalette.lastError
                    ? Settings.colors.foreground.error : Settings.colors.foreground.main
            }
        }
    }
}
