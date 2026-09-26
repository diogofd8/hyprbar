import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs
import qs.components
import qs.core as Core

import "powermanager" as PowerUI

Pane {
    id: root
    signal dismissRequested()

    readonly property string panelBackgroundColor: Settings.colors.bgMain
    readonly property real targetImplicitHeight: panelContent.implicitHeight + root.topPadding + root.bottomPadding
    property string requestedPowerMode: ""
    readonly property bool usingPowerProfiles:
        PowerUI.Configuration.powerProfileBackend === "power-profiles-daemon"
    readonly property bool powerModesAvailable:
        !root.usingPowerProfiles || Core.PowerProfiles.available
    readonly property string activePowerMode: root.usingPowerProfiles
        ? Core.PowerProfiles.activeProfile : root.requestedPowerMode

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

    padding: PowerUI.Configuration.widgetBoxPadding
    implicitHeight: root.targetImplicitHeight
    clip: true

    background: Rectangle {
        color: Qt.alpha(root.panelBackgroundColor, Settings.colors.bgOpacity)

        border.width: 1
        border.color: Qt.alpha(Settings.colors.fgMain, Settings.colors.hoverOpacity)

        // Hide the top border
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: parent.border.width
            color: root.panelBackgroundColor
        }
    }

    contentItem: ColumnLayout {
        id: panelContent

        // ────── Top Row ──────
        RowLayout {
            Layout.fillWidth: true
            spacing: PowerUI.Configuration.topBarSpacing

            Item {
                id: powerModeControl
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
                    spacing: PowerUI.Configuration.topBarSpacing

                    HexagonButton {
                        id: powerSaverButton

                        enabled: root.powerModesAvailable
                        bgFill: root.activePowerMode === "power-saver"
                            ? Settings.colors.accentMain : Settings.colors.bgTint2
                        glyph: PowerUI.Configuration.powerMode[0].icon
                        glyphSize: PowerUI.Configuration.secondaryButtonSize
                        glyphColor: Settings.colors.fgMain

                        onLeftClicked: root.setPowerMode("power-saver")
                    }

                    HexagonButton {
                        id: balancedButton

                        enabled: root.powerModesAvailable
                        bgFill: root.activePowerMode === "balanced"
                            ? Settings.colors.accentMain : Settings.colors.bgTint2
                        glyph: PowerUI.Configuration.powerMode[1].icon
                        glyphSize: PowerUI.Configuration.secondaryButtonSize
                        glyphColor: Settings.colors.fgMain
                        glyphHorizontalOffset: -1

                        onLeftClicked: root.setPowerMode("balanced")
                    }

                    HexagonButton {
                        id: performanceButton

                        enabled: root.powerModesAvailable
                            && (!root.usingPowerProfiles
                                || Core.PowerProfiles.hasPerformanceProfile)
                        bgFill: root.activePowerMode === "performance"
                            ? Settings.colors.accentMain : Settings.colors.bgTint2
                        glyph: PowerUI.Configuration.powerMode[2].icon
                        glyphSize: PowerUI.Configuration.secondaryButtonSize -1
                        glyphColor: Settings.colors.fgMain

                        onLeftClicked: root.setPowerMode("performance")
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
            }

            Text {
                text: "MODE:"
                elide: Text.ElideRight
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: PowerUI.Configuration.subTextFontSize
            }

            Text {
                text: root.powerModeLabel(root.activePowerMode)
                elide: Text.ElideRight
                color: Settings.colors.accentMain
                font.family: Settings.labelFontFamily
                font.pixelSize: PowerUI.Configuration.subTextFontSize
            }
        }

        // ────── Separator ──────
        Separator {
            Layout.fillWidth: true
            Layout.topMargin: 1
            Layout.bottomMargin: PowerUI.Configuration.mainColumnGap
            color: Settings.colors.bgTint4
        }

        // ────── Battery Entries ──────
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: PowerUI.Configuration.contentWidth
            implicitHeight: Math.min(contents.implicitHeight, PowerUI.Configuration.listMaxHeight)
            contentWidth: width
            contentHeight: contents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contents
                readonly property var cumulativeBattery: Core.PowerSupply.display
                width: scroll.width
                spacing: PowerUI.Configuration.sectionSpacing

                ColumnLayout {
                    id: batterySection

                    Layout.fillWidth: true
                    visible: true
                    spacing: PowerUI.Configuration.pwrEntryRowSpacing

                    RowLayout {
                        Layout.bottomMargin: 4

                        Text {

                            text: "BATTERY"
                            color: Settings.colors.fgMain
                            font.family: Settings.labelFontFamily
                            font.bold: true
                            font.pixelSize: PowerUI.Configuration.columnLabelFontSize
                        }

                        Text {
                            text: "-"
                            color: Settings.colors.fgMain
                            font.family: Settings.labelFontFamily
                            font.bold: true
                            font.pixelSize: PowerUI.Configuration.columnLabelFontSize
                        }

                        Percentage {
                            value: contents.cumulativeBattery.value
                            fontSize: PowerUI.Configuration.columnLabelFontSize
                            fontFamily: Settings.labelFontFamily
                        }
                    }

                    Repeater {
                        model: Core.PowerSupply.batteryEntryModel
                        delegate: PowerUI.PowerEntry {
                            Layout.fillWidth: true

                            onDismissRequested: root.dismissRequested()
                        }
                    }

                    Text {
                        visible: Core.PowerSupply.batteryEntryModel.count === 0
                        text: "No batteries available"
                        color: Settings.colors.fgMain
                        opacity: 0.7
                        font.family: Settings.labelFontFamily
                        font.pixelSize: PowerUI.Configuration.subTextFontSize
                    }
                }

                ColumnLayout {
                    id: devicesSection

                    Layout.fillWidth: true
                    visible: Core.PowerSupply.peripheralEntryModel.count > 0
                    spacing: PowerUI.Configuration.pwrEntryRowSpacing

                    Text {
                        Layout.bottomMargin: 4

                        text: "CONNECTED DEVICES"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: PowerUI.Configuration.columnLabelFontSize
                    }

                    Repeater {
                        model: Core.PowerSupply.peripheralEntryModel
                        delegate: PowerUI.PowerEntry {
                            Layout.fillWidth: true

                            onDismissRequested: root.dismissRequested()
                        }
                    }
                }

                RowLayout {
                    Layout.bottomMargin: PowerUI.Configuration.widgetBoxPadding
                    Text {

                        text: "CAFFEINE MODE"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.bold: true
                        font.pixelSize: PowerUI.Configuration.columnLabelFontSize
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                    }

                    HexagonSwitch {
                        actionable: true
                        checked: Core.Caffeine.enabled
                        onClicked: Core.Caffeine.toggle()

                        backgroundColor: root.panelBackgroundColor
                    }
                }
            }
        }
    }
}
