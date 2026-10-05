import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components
import qs.core as Core

import "powermanager" as PowerUI

Pane {
    id: root

    readonly property string panelBackgroundColor: Settings.colors.bgMain
    property string requestedPowerMode: ""
    readonly property bool usingPowerProfiles:
        PowerUI.Configuration.powerProfileBackend === "power-profiles-daemon"
    readonly property bool powerModesAvailable: !root.usingPowerProfiles || Core.PowerProfiles.available
    readonly property bool hasManuallyEnforcedPowerMode: Core.PowerProfiles.settingMode === "manual"
    readonly property string activePowerMode: root.usingPowerProfiles ? Core.PowerProfiles.activeProfile : root.requestedPowerMode

    function setPowerMode(profile) {
        if (!PowerUI.PowerActions.setConfiguredPowerProfile(
                profile, PowerUI.Configuration.powerProfileBackend))
            return

        if (!root.usingPowerProfiles)
            root.requestedPowerMode = profile
    }

    function powerModeLabel(profile) {
        switch (profile) {
        case "power-saver": return "PowerSave"
        case "balanced": return "Balanced"
        case "performance": return "Performance"
        default: return "Unavailable"
        }
    }

    padding: WidgetConfiguration.dropDownWindowPadding
    implicitHeight: panelContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    // PopoutHost draws the panel background shared by every widget. Null, not
    // omitted, so the Controls style doesn't add a default one.
    background: null

    contentItem: ColumnLayout {
        id: panelContent

        // ────── Top Row ──────
        ColumnLayout {
            id: headerContainer
            spacing: WidgetConfiguration.mainRowPadding

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: WidgetConfiguration.mainRowPadding
                Layout.rightMargin: WidgetConfiguration.mainRowPadding
                spacing: WidgetConfiguration.mainRowHSpacing

                Item {
                    id: powerModeControl
                    Layout.topMargin: WidgetConfiguration.hexBtnVPadding
                    Layout.bottomMargin: WidgetConfiguration.hexBtnVPadding
                    implicitWidth: powerModeToggles.implicitWidth
                    implicitHeight: powerModeToggles.implicitHeight

                    Rectangle {
                        id: powerModeBg

                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                            leftMargin: powerSaverButton.width / 2
                            rightMargin: performanceButton.width / 2
                        }

                        color: Settings.colors.bgTint2
                    }

                    RowLayout {
                        id: powerModeToggles
                        anchors.fill: parent
                        spacing: WidgetConfiguration.hexBtnSpacing

                        HexagonButton {
                            id: powerSaverButton

                            enabled: root.powerModesAvailable
                            bgFill: root.activePowerMode === "power-saver"
                                ? Settings.colors.accentMain : Settings.colors.bgTint3
                            glyph: PowerUI.Configuration.powerMode["power-saver"]
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: root.activePowerMode === "power-saver"
                                ? Settings.colors.fgDark
                                : Settings.colors.fgMain

                            onLeftClicked: root.setPowerMode("power-saver")
                        }

                        HexagonButton {
                            id: balancedButton

                            enabled: root.powerModesAvailable
                            bgFill: root.activePowerMode === "balanced"
                                ? Settings.colors.accentMain : Settings.colors.bgTint3
                            glyph: PowerUI.Configuration.powerMode["balanced"]
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz
                            glyphColor: root.activePowerMode === "balanced"
                                ? Settings.colors.fgDark
                                : Settings.colors.fgMain
                            glyphHorizontalOffset: -1

                            onLeftClicked: root.setPowerMode("balanced")
                        }

                        HexagonButton {
                            id: performanceButton

                            enabled: root.powerModesAvailable
                                && (!root.usingPowerProfiles
                                    || Core.PowerProfiles.hasPerformanceProfile)
                            bgFill: root.activePowerMode === "performance"
                                ? Settings.colors.accentMain : Settings.colors.bgTint3
                            glyph: PowerUI.Configuration.powerMode["performance"]
                            glyphSize: WidgetConfiguration.widgetEmbeddedIconSz - 3
                            paddingOffset: 3
                            glyphColor: root.activePowerMode === "performance"
                                ? Settings.colors.fgDark
                                : Settings.colors.fgMain

                            onLeftClicked: root.setPowerMode("performance")
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                SquaredButton {
                    id: restoreTlpButton

                    enabled: root.hasManuallyEnforcedPowerMode && !PowerUI.PowerActions.resettingTlpProfile
                    opacity: root.hasManuallyEnforcedPowerMode ? 1 : Settings.colors.disabledOpacity

                    glyph: PowerUI.Configuration.restoreTlpButton
                    glyphSize: WidgetConfiguration.widgetMainIconSz
                    useMetrics: true
                    color: Settings.colors.fgMain

                    onLeftClicked: root.setPowerMode("auto")

                    NumberAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1500
                        loops: Animation.Infinite
                        running: PowerUI.PowerActions.resettingTlpProfile

                        onStopped: restoreTlpButton.rotation = 0
                    }
                }

                Text {
                    text: "MODE:"
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.widgetMainFontSz
                }

                Text {
                    text: root.powerModeLabel(root.activePowerMode)
                    elide: Text.ElideRight
                    color: Settings.colors.accentMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.widgetMainFontSz
                }
            }

            // ────── Separator ──────
            Separator {
                Layout.fillWidth: true
                Layout.topMargin: 1
                Layout.bottomMargin: WidgetConfiguration.mainRowVMargin
                color: Settings.colors.bgTint4
            }
        }

        // ────── Battery Entries ──────
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: PowerUI.Configuration.contentWidth
            implicitHeight: Math.min(contents.implicitHeight, WidgetConfiguration.rowContentMaxHeight)
            contentWidth: width
            contentHeight: contents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contents
                readonly property var cumulativeBattery: Core.PowerSupply.display
                width: scroll.width
                spacing: WidgetConfiguration.sectionVSpacing

                ColumnLayout {
                    id: batterySection

                    Layout.fillWidth: true
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    RowLayout {
                        Text {
                            text: "BATTERY"
                            color: Settings.colors.fgMain
                            font.family: Settings.labelFontFamily
                            font.bold: true
                            font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                        }

                        Text {
                            text: "-"
                            color: Settings.colors.fgMain
                            font.family: Settings.labelFontFamily
                            font.bold: true
                            font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                        }

                        Percentage {
                            value: contents.cumulativeBattery.value
                            fontSize: WidgetConfiguration.sectionRowLabelFontSz
                            fontFamily: Settings.labelFontFamily
                        }
                    }

                    Repeater {
                        model: Core.PowerSupply.batteryEntryModel
                        delegate: PowerUI.PowerEntry {
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        visible: Core.PowerSupply.batteryEntryModel.count === 0
                        text: "No batteries available"
                        color: Settings.colors.fgMain
                        opacity: Settings.colors.dimOpacity
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz
                    }
                }

                ColumnLayout {
                    id: devicesSection

                    Layout.fillWidth: true
                    visible: Core.PowerSupply.peripheralEntryModel.count > 0
                    spacing: WidgetConfiguration.sectionContentVSpacing

                    Text {
                        text: "CONNECTED DEVICES"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
                    }

                    Repeater {
                        model: Core.PowerSupply.peripheralEntryModel
                        delegate: PowerUI.PowerEntry {
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        // ────── Caffeine Mode ──────
        RowLayout {
            Layout.topMargin: WidgetConfiguration.mainRowVMargin
            Layout.bottomMargin: WidgetConfiguration.mainRowPadding

            Text {
                text: "CAFFEINE MODE"
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.bold: true
                font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
            }

            Item {
                Layout.fillWidth: true
            }

            HexagonSwitch {
                actionable: true
                checked: Core.Caffeine.enabled
                onClicked: Core.Caffeine.toggle()

                bgFill: root.panelBackgroundColor
            }
        }
    }
}
