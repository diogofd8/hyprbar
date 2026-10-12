import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell.Services.Notifications

import qs
import qs.components

NotificationSurface {
    id: root

    required property var entry
    property bool popup: false
    property bool showApplication: true
    property bool expanded: popup
    readonly property bool hasDetails: root.detailsAvailable()
    readonly property string receivedTime: root.formattedTime()

    padding: Settings.notificationPopupPadding
    implicitHeight: contents.implicitHeight + topPadding + bottomPadding
    clip: true
    hoverEnabled: true

    background: Rectangle {
        color: Settings.colors.bgTint2

        Rectangle {
            width: Settings.notificationPopupAttentionBarWidth
            height: parent.height
            color: Settings.colors.accentError
            visible: root.entry?.urgency === NotificationUrgency.Critical
        }
    }

    contentItem: ColumnLayout {
        id: contents

        spacing: Settings.notificationPopupContentSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Settings.notificationPopupHeaderSpacing

            NotificationAppIcon {
                iconSize: Settings.notificationPopupAppIconSize
                visible: root.showApplication
                source: root.showApplication ? root.entry?.appIcon ?? "" : ""
                desktopEntry: root.entry?.desktopEntry ?? ""
                appName: root.entry?.appName ?? ""
            }

            Text {
                Layout.fillWidth: true
                text: root.showApplication ? root.entry?.appName ?? "" : root.receivedTime
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.notificationPopupFontSize
                opacity: Settings.colors.dimOpacity
            }

            Text {
                visible: root.showApplication
                text: root.receivedTime
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.notificationPopupFontSize
                opacity: Settings.colors.dimOpacity
            }

            SquaredButton {
                visible: root.hasDetails
                glyph: Settings.notificationPopupIcon.expand
                glyphSize: Settings.notificationPopupButtonIconSize
                padding: Settings.notificationPopupButtonPadding
                glyphRotation: root.expanded ? 180 : 0

                onLeftClicked: root.expanded = !root.expanded

                Controls.ToolTip.visible: isHovered
                Controls.ToolTip.text: root.expanded ? "Collapse" : "Expand"

                Behavior on glyphRotation { Anim {} }
            }

            SquaredButton {
                glyph: Settings.notificationPopupIcon.clear
                glyphSize: Settings.notificationPopupButtonIconSize
                padding: Settings.notificationPopupButtonPadding
                onLeftClicked: root.dismiss()

                Controls.ToolTip.visible: isHovered
                Controls.ToolTip.text: "Dismiss"
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.entry?.summary ?? ""
            textFormat: Text.PlainText
            color: Settings.colors.fgMain
            font.family: Settings.labelFontFamily
            font.pixelSize: Settings.notificationPopupTitleFontSize
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: root.expanded ? Settings.notificationPopupTitleLineLimit : 1
            wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
        }

        Text {
            Layout.fillWidth: true
            visible: !root.expanded && (root.entry?.body.length ?? 0) > 0
            text: root.entry?.body ?? ""
            textFormat: Text.StyledText
            elide: Text.ElideRight
            maximumLineCount: 1
            color: Settings.colors.fgMain
            font.family: Settings.labelFontFamily
            font.pixelSize: Settings.notificationPopupFontSize
            opacity: Settings.colors.dimOpacity
        }

        CollapsibleRow {
            Layout.fillWidth: true
            shown: root.expanded && root.hasDetails

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Settings.notificationPopupSpacing

                Text {
                    Layout.fillWidth: true
                    visible: (root.entry?.body.length ?? 0) > 0
                    text: root.entry?.body ?? ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: root.popup ? Settings.notificationPopupBodyLineLimit : Settings.notificationPopupExpandedBodyLineLimit
                    elide: Text.ElideRight
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Settings.notificationPopupFontSize
                }

                Image {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Settings.notificationPopupImageHeight
                    visible: root.expanded && (root.entry?.image.length ?? 0) > 0
                    source: visible ? root.entry.image : ""
                    fillMode: Image.PreserveAspectFit
                    sourceSize.height: Settings.notificationPopupImageHeight * Settings.notificationPopupImageSourceScale
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Settings.notificationPopupSpacing
                    visible: (root.entry?.actions.length ?? 0) > 0

                    Repeater {
                        model: root.entry?.actions ?? []

                        Controls.Button {
                            id: actionButton

                            required property var modelData

                            text: modelData.text || "Open"
                            padding: Settings.notificationPopupPadding
                            onClicked: modelData.invoke()

                            background: Rectangle {
                                color: actionButton.hovered ? Settings.colors.bgTint4 : Settings.colors.bgTint3
                            }

                            contentItem: Text {
                                text: actionButton.text
                                color: Settings.colors.fgMain
                                font.family: Settings.labelFontFamily
                                font.pixelSize: Settings.notificationPopupFontSize
                            }
                        }
                    }
                }
            }
        }
    }

    // ────── Helper Functions ──────
    function dismiss(): void {
        root.dismissEntries([root.entry])
    }

    function detailsAvailable(): bool {
        if ((root.entry?.body.length ?? 0) > 0)
            return true
        if ((root.entry?.image.length ?? 0) > 0)
            return true

        return (root.entry?.actions.length ?? 0) > 0
    }

    function formattedTime(): string {
        if (!root.entry)
            return ""

        return Qt.formatDateTime(root.entry.receivedAt, "HH:mm")
    }
}
