import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import qs
import qs.widgets
import qs.components

Controls.Pane {
    id: root
    required property var model

    readonly property bool hasDetails: shouldShowBatteryDetails()

    // ────── Dimensioning ──────
    leftPadding: WidgetConfiguration.entryHPadding
    rightPadding: WidgetConfiguration.entryHPadding
    topPadding: WidgetConfiguration.entryVPadding
    bottomPadding: WidgetConfiguration.entryVPadding
    implicitHeight: mainContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    Behavior on implicitHeight { Anim {} }

    background: Rectangle {
        color: Settings.colors.bgTint2
    }

    contentItem: RowLayout {
        id: mainContent
        spacing: WidgetConfiguration.entryHPadding

        Glyph {
            id: pwrEntryIcon
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: WidgetConfiguration.entryIconHPadding
            Layout.rightMargin: WidgetConfiguration.entryIconHPadding

            icon: root.model.icon
            iconSize: WidgetConfiguration.entryRowMainIconSz
            useMetrics: false
            iconColor: root.statusColor()
        }

        ColumnLayout {
            spacing: WidgetConfiguration.entryRowVSpacing

            RowLayout {
                id: mainRow

                Layout.fillWidth: true
                Layout.preferredHeight: WidgetConfiguration.entryRowMainIconSz
                spacing: WidgetConfiguration.entryTitleRowHSpacing

                Text {
                    id: pwrEntryName
                    Layout.fillWidth: true

                    text: root.model.kind === "battery"
                        ? batteryLabel(root.model.name)
                        : root.model.name
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
                }

                Text {
                    visible: root.model.statusText.length > 0
                    text: shortStatus(root.model.statusText)
                    color: root.statusColor()
                    opacity: Settings.colors.dimOpacity
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.widgetMainFontSz
                }

                Item {
                    Layout.fillWidth: true
                }

                Percentage {
                    height: parent.height
                    value: root.model.value

                    fontFamily: Settings.labelFontFamily
                    fontSize: WidgetConfiguration.widgetMainFontSz
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: WidgetConfiguration.entryExtendedRowHSpacing
                clip: true
                visible: root.hasDetails
                opacity: Settings.colors.dimOpacity

                RowLayout {
                    id: batteryHealth
                    // very unlikely battery health is 100% so we remove spacing because
                    // percentage already allocates enough space
                    spacing: 0

                    Text {
                        visible: root.model.healthSupported
                        text: "Health:"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMainFontSz
                    }

                    Percentage {
                        visible: root.model.healthSupported
                        height: parent.height
                        value: root.model.health
                        fontFamily: Settings.labelFontFamily
                        fontSize: WidgetConfiguration.widgetMainFontSz
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    id: pwrEstimation
                    spacing: WidgetConfiguration.entryExtendedRowHSpacing

                    Text {
                        visible: root.model.autonomy > 0
                        text: "Autonomy:"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMainFontSz
                    }

                    Text {
                        visible: root.model.autonomy > 0
                        text: root.formatDuration(root.model.autonomy)
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMainFontSz
                    }

                    Text {
                        visible: root.model.fullIn > 0
                        text: "Full In:"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMainFontSz
                    }

                    Text {
                        visible: root.model.fullIn > 0
                        text: root.formatDuration(root.model.fullIn)
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.widgetMainFontSz
                    }
                }
            }
        }
    }

    // ────── Row logic ──────
    function shouldShowBatteryDetails() {
        if (root.model.kind !== "battery")
            return false
        if (root.model.autonomy > 0)
            return true
        if (root.model.fullIn > 0)
            return true
        if (root.model.healthSupported)
            return true
        return false
    }

    function statusColor() {
        if (root.model.charging)
            return Settings.colors.accentCharging
        if (root.model.state === "empty")
            return Settings.colors.accentError
        if (root.model.state === "alert")
            return Settings.colors.accentAlert
        return Settings.colors.fgMain
    }

    function formatDuration(seconds) {
        const totalMinutes = Math.ceil(seconds / 60)
        const hours = Math.floor(totalMinutes / 60)
        const minutes = totalMinutes % 60

        return String(hours).padStart(2, "0") + ":" + String(minutes).padStart(2, "0")
    }

    function shortStatus(status) {
        // The missing status are not needed to shorten so we pass as is
        switch (status) {
            case "Discharging":
                return "In use"
            case "Waiting to charge":
            case "Waiting to discharge":
                return "Waiting"
            case "Fully charged":
                return "Full"
            default:
                return status
            }
    }

    function batteryLabel(batteryName) {
        if (batteryName === Configuration.internalBat)
            return "Internal";
        if (batteryName === Configuration.externalBat)
            return "External";

        return "Unknown";
    }
}
