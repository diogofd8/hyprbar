import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import qs
import qs.components

Controls.Pane {
    id: root
    required property var model
    signal dismissRequested()

    readonly property bool hasDetails: shouldShowBatteryDetails()

    padding: Configuration.pwrEntryPadding
    implicitHeight: mainContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    Behavior on implicitHeight {
        SmoothedAnimation {
            duration: Configuration.transitionMs
            velocity: -1
            reversingMode: SmoothedAnimation.Eased
        }
    }

    background: Rectangle {
        color: Settings.colors.bgTint2
    }

    contentItem: RowLayout {
        id: mainContent
        spacing: Configuration.pwrEntryPadding

        Glyph {
            id: pwrEntryIcon
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6
            Layout.rightMargin: 6

            icon: root.model.icon
            iconSize: Configuration.mainButtonSize
            useMetrics: false
            iconColor: root.statusColor()
        }

        ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Configuration.pwrEntryPadding

                Text {
                    id: pwrEntryName
                    Layout.fillWidth: true

                    text: root.model.kind === "battery"
                        ? batteryLabel(root.model.name)
                        : root.model.name
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.pwrEntryNameFontSize
                }

                Text {
                    visible: root.model.statusText.length > 0
                    text: shortStatus(root.model.statusText)
                    color: root.statusColor()
                    opacity: 0.75
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.subTextFontSize
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                }

                Percentage {
                    height: parent.height
                    value: root.model.value

                    fontFamily: Settings.labelFontFamily
                    fontSize: Configuration.pwrEntryNameFontSize
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: visible ? Configuration.pwrEntryExpandedRowSpacing : 0
                Layout.bottomMargin: visible ? Configuration.pwrEntryExpandedRowSpacing : 0
                spacing: 0
                clip: true
                visible: root.hasDetails
                opacity: 0.7

                Text {
                    visible: root.model.healthSupported
                    text: "Health:"
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Settings.smallCapsFontSize
                }

                Percentage {
                    visible: root.model.healthSupported
                    height: parent.height
                    value: root.model.health
                    fontFamily: Settings.labelFontFamily
                    fontSize: Settings.smallCapsFontSize
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                }

                RowLayout {
                    id: pwrEstimation
                    Layout.rightMargin: Configuration.pwrEntryPadding

                    Text {
                        visible: root.model.autonomy > 0
                        text: "Autonomy:"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: Settings.smallCapsFontSize
                    }

                    Text {
                        visible: root.model.autonomy > 0
                        text: root.formatDuration(root.model.autonomy)
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: Settings.smallCapsFontSize
                    }

                    Text {
                        visible: root.model.fullIn > 0
                        text: "Full In:"
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: Settings.smallCapsFontSize
                    }

                    Text {
                        visible: root.model.fullIn > 0
                        text: root.formatDuration(root.model.fullIn)
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: Settings.smallCapsFontSize
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
        if (root.model.state === "empty" || root.model.state === "discharging")
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
