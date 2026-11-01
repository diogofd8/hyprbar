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
    property string draftSeed: ""
    readonly property bool canApply: picker.valid && Core.ThemeControl.canApplyAccent && !Core.ThemeControl.busy
        && (Core.SystemPalette.source !== "fixed"
            || Core.ThemeControl.normalizeSeed(picker.selectedSeed) !== Core.ThemeControl.normalizeSeed(Core.SystemPalette.accentSeed))
    readonly property string feedback: {
        if (Core.ThemeControl.busy) return Core.ThemeControl.phase === "spectra" ? "Saving colour…" : "Applying theme…"
        return Core.ThemeControl.lastError || Core.ThemeControl.spectraError || Core.SystemPalette.lastError
    }
    signal dismissed()

    function selectSeed(seed: string): void {
        draftSeed = seed
        // Reselecting a saved seed must also reset the sliders when the source
        // string already matches; in that case onSourceSeedChanged does not fire.
        picker.resetFromSource()
    }
    Component.onCompleted: {
        activePage = Core.SystemPalette.source === "matugen" ? matugenPage : oxidyePage
        selectSeed(Core.SystemPalette.fixedSeed)
    }
    Connections {
        target: Core.SystemPalette
        function onFixedSeedChanged(): void { root.selectSeed(Core.SystemPalette.fixedSeed) }
    }
    Connections {
        target: Core.ThemeControl
        function onAccentApplied(seed: string): void { root.selectSeed(seed) }
    }

    WlrLayershell.namespace: "hyprbar-thememanager"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: ThemeUI.Configuration.widgetWidth
    implicitHeight: Math.ceil(panel.implicitHeight)
    color: "transparent"

    BackgroundSurface {
        id: panelBackground
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: Settings.colors.background.main }
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
        padding: WidgetConfiguration.dropDownWindowPadding
        implicitHeight: panelContent.implicitHeight + topPadding + bottomPadding
        background: null
        Keys.onEscapePressed: root.dismissed()

        contentItem: ColumnLayout {
            id: panelContent
            spacing: WidgetConfiguration.mainRowHSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: WidgetConfiguration.mainRowPadding
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: WidgetConfiguration.mainRowPadding
                    Layout.rightMargin: WidgetConfiguration.mainRowPadding
                    spacing: WidgetConfiguration.mainRowHSpacing

                    ThemeUI.ThemeTabs {
                        HexagonButton {
                            objectName: "oxidyePageButton"
                            bgFill: root.activePage === root.oxidyePage
                                ? Settings.colors.background.accent : Settings.colors.background.tint3
                            glyph: ThemeUI.Configuration.pageIcons[root.oxidyePage]
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: root.activePage === root.oxidyePage
                                ? Settings.colors.foreground.contrast : Settings.colors.foreground.main
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: "Oxidye"
                            Accessible.checked: root.activePage === root.oxidyePage
                            onLeftClicked: root.activePage = root.oxidyePage
                        }
                        HexagonButton {
                            objectName: "matugenPageButton"
                            bgFill: root.activePage === root.matugenPage
                                ? Settings.colors.background.accent : Settings.colors.background.tint3
                            glyph: ThemeUI.Configuration.pageIcons[root.matugenPage]
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: root.activePage === root.matugenPage
                                ? Settings.colors.foreground.contrast : Settings.colors.foreground.main
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: "Matugen"
                            Accessible.checked: root.activePage === root.matugenPage
                            onLeftClicked: root.activePage = root.matugenPage
                        }
                    }
                    Text {
                        text: "MODE:"
                        elide: Text.ElideRight
                        color: Settings.colors.foreground.main
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMainFontSz
                    }
                    Text {
                        objectName: "themeSourceLabel"
                        // The applied source; the tabs only navigate pages.
                        text: Core.SystemPalette.source === "matugen" ? "Matugen"
                            : Core.SystemPalette.source === "fixed" ? "Oxidye" : "Unavailable"
                        elide: Text.ElideRight
                        color: Settings.colors.foreground.accent
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMainFontSz
                    }
                    Item { Layout.fillWidth: true }
                    ThemeUI.ThemeTabs {
                        enabled: Core.ThemeControl.canToggleMode && !Core.ThemeControl.busy
                        opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity

                        HexagonButton {
                            objectName: "lightModeButton"
                            bgFill: Settings.theme === "light"
                                ? Settings.colors.background.accent : Settings.colors.background.tint3
                            glyph: ThemeUI.Configuration.lightIcon
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: Settings.theme === "light"
                                ? Settings.colors.foreground.contrast : Settings.colors.foreground.main
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: "Light theme"
                            Accessible.checked: Settings.theme === "light"
                            onLeftClicked: if (Settings.theme !== "light") Core.ThemeControl.toggleMode()
                        }
                        HexagonButton {
                            objectName: "darkModeButton"
                            bgFill: Settings.theme === "dark"
                                ? Settings.colors.background.accent : Settings.colors.background.tint3
                            glyph: ThemeUI.Configuration.darkIcon
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: Settings.theme === "dark"
                                ? Settings.colors.foreground.contrast : Settings.colors.foreground.main
                            // Measured: the crescent renders half a pixel left of centre.
                            glyphHorizontalOffset: 0.5
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: "Dark theme"
                            Accessible.checked: Settings.theme === "dark"
                            onLeftClicked: if (Settings.theme !== "dark") Core.ThemeControl.toggleMode()
                        }
                    }
                }
                Separator {
                    Layout.fillWidth: true
                    Layout.topMargin: 1
                    color: Settings.colors.background.tint4
                }
            }

            Flickable {
                id: scroll
                readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: scroll }
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                implicitHeight: Math.min(pages.implicitHeight, WidgetConfiguration.rowContentMaxHeight)
                contentWidth: width
                contentHeight: pages.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    id: pages
                    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: pages }
                    width: scroll.width
                    readonly property real pageProgress: width > 0 ? -fixedPage.x / width : root.activePage
                    implicitHeight: fixedPage.implicitHeight * (1 - pageProgress)
                    clip: true

                    Item {
                        id: fixedPage
                        width: pages.width
                        implicitHeight: fixedContents.implicitHeight
                        x: (root.oxidyePage - root.activePage) * pages.width
                        enabled: root.activePage === root.oxidyePage
                        visible: x + width > 0
                        Behavior on x {
                            enabled: root.backingWindowVisible
                            Anim { easing.bezierCurve: Motion.standardCurve }
                        }
                        ColumnLayout {
                            id: fixedContents
                            width: parent.width
                            spacing: WidgetConfiguration.sectionVSpacing
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: WidgetConfiguration.entryHPadding
                                Layout.rightMargin: WidgetConfiguration.entryHPadding
                                spacing: WidgetConfiguration.mainRowHSpacing
                                Text {
                                    text: "ACCENT SPECTRUM"
                                    font.family: Settings.labelFontFamily
                                    font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                                    font.bold: true
                                    color: Settings.colors.foreground.main
                                }
                                Item { Layout.fillWidth: true }
                                ThemeUI.ApplyButton {
                                    objectName: "applyAccentButton"
                                    sample: picker.previewColor
                                    enabled: root.canApply
                                    onClicked: Core.ThemeControl.applyAccent(picker.selectedSeed)
                                }
                            }
                            ThemeUI.HsvColorPicker {
                                id: picker
                                objectName: "accentPicker"
                                Layout.fillWidth: true
                                Layout.leftMargin: WidgetConfiguration.entryHPadding
                                Layout.rightMargin: WidgetConfiguration.entryHPadding
                                sourceSeed: root.draftSeed
                                enabled: valid && Core.ThemeControl.canApplyAccent && !Core.ThemeControl.busy
                            }
                            Separator { Layout.fillWidth: true; color: Settings.colors.background.tint4 }
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: WidgetConfiguration.entryHPadding
                                Layout.rightMargin: WidgetConfiguration.entryHPadding
                                spacing: WidgetConfiguration.mainRowHSpacing
                                Text {
                                    text: "SAVED COLORS"
                                    font.family: Settings.labelFontFamily
                                    font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                                    font.bold: true
                                    color: Settings.colors.foreground.main
                                }
                                Flickable {
                                    objectName: "savedSpectraScroll"
                                    Layout.fillWidth: true
                                    implicitHeight: ThemeUI.Configuration.savedColorHeight
                                    contentHeight: height
                                    contentWidth: spectrumRow.width
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    flickableDirection: Flickable.HorizontalFlick
                                    Row {
                                        id: spectrumRow
                                        spacing: WidgetConfiguration.hexBtnSpacing
                                        Repeater {
                                            model: Core.ThemeControl.savedSpectra
                                            ThemeUI.ThemeButton {
                                                required property string modelData
                                                objectName: "savedSpectrum-" + modelData
                                                implicitHeight: ThemeUI.Configuration.savedColorHeight
                                                text: "Select " + modelData
                                                colorSample: true
                                                selected: modelData === Core.ThemeControl.normalizeSeed(picker.selectedSeed)
                                                glyph: selected ? ThemeUI.Configuration.applyIcon : ""
                                                glyphSize: ThemeUI.Configuration.smallGlyphSize
                                                bgFill: {
                                                    const seed = Core.Oklch.parse(modelData)
                                                    return Core.Oklch.displayColor(seed.lightness, seed.chroma, seed.hue)
                                                }
                                                enabled: Core.ThemeControl.canApplyAccent && !Core.ThemeControl.busy
                                                onClicked: root.selectSeed(modelData)
                                            }
                                        }
                                    }
                                    Controls.ScrollBar.horizontal: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }
                                }
                                ThemeUI.ThemeButton {
                                    objectName: "saveSpectrumButton"
                                    implicitHeight: ThemeUI.Configuration.savedColorHeight
                                    glyphSize: ThemeUI.Configuration.smallGlyphSize
                                    text: "Save selected spectrum"
                                    glyph: ThemeUI.Configuration.saveIcon
                                    enabled: picker.valid && Core.ThemeControl.spectraWritable && !Core.ThemeControl.busy
                                        && !Core.ThemeControl.savedSpectra.includes(Core.ThemeControl.normalizeSeed(picker.selectedSeed))
                                    onClicked: Core.ThemeControl.saveSpectrum(picker.selectedSeed)
                                }
                            }
                        }
                    }
                    Item {
                        width: pages.width
                        x: (root.matugenPage - root.activePage) * pages.width
                        // The Matugen page intentionally has no controls yet.
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
                visible: text.length > 0
                text: root.feedback
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.family: Settings.labelFontFamily
                font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                color: Core.ThemeControl.lastError || Core.ThemeControl.spectraError || Core.SystemPalette.lastError
                    ? Settings.colors.foreground.error : Settings.colors.foreground.main
            }
        }
    }
}
