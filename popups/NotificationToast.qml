import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell.Services.Notifications

import qs
import qs.components

NotificationSurface {
    id: root

    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }

    required property var entry
    readonly property string receivedTime: root.formattedTime()
    readonly property bool hasActions: (root.entry?.actions.length ?? 0) > 0
    readonly property bool hasImage: (root.entry?.image.length ?? 0) > 0

    Connections {
        target: root.entry

        function onPopupExpired(): void {
            root.dismissEntries([root.entry], true)
        }

        function onPopupExpiresAtChanged(): void {
            // A replacement starts a fresh timeout and keeps its toast visible.
            if (root.popupOnly && root.entry.popupExpiresAt > 0)
                root.cancelDismissal()
        }
    }

    TapHandler {
        parent: root
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => root.handleTap(eventPoint.scenePosition, button)
    }

    // ────── Dimensioning ──────
    leftPadding: PopupConfiguration.notificationPopupPaddingX
    rightPadding: PopupConfiguration.notificationPopupPaddingX
    topPadding: PopupConfiguration.notificationPopupPaddingY
    bottomPadding: PopupConfiguration.notificationPopupPaddingY

    implicitHeight: contents.implicitHeight + topPadding + bottomPadding
    clip: true
    hoverEnabled: true

    background: BackgroundRectangle {
        color: Settings.colors.background.main

        BackgroundRectangle {
            width: PopupConfiguration.notificationPopupAttentionBarWidth
            height: parent.height
            color: Settings.colors.background.error
            visible: root.entry?.urgency === NotificationUrgency.Critical
        }
    }

    contentItem: ColumnLayout {
        id: contents
        spacing: PopupConfiguration.notificationMainVMargin

        RowLayout {
            Layout.fillWidth: true
            spacing: PopupConfiguration.notificationPopupHeaderHSpacing

            NotificationAppIcon {
                iconSize: PopupConfiguration.notificationPopupAppIconSize
                source: root.entry?.appIcon ?? ""
                desktopEntry: root.entry?.desktopEntry ?? ""
                appName: root.entry?.appName ?? ""
            }

            Text {
                Layout.minimumWidth: 0
                text: root.entry?.appName ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Settings.colors.foreground.muted
                font.family: Settings.labelFontFamily
                font.pixelSize: PopupConfiguration.notificationPopupHeaderFontSize

            }

            Circle {
                Layout.alignment: Qt.AlignCenter

                diameter: Settings.separatorDotSize
                color: Settings.colors.foreground.muted
            }

            Text {
                text: root.receivedTime
                color: Settings.colors.foreground.muted
                font.family: Settings.labelFontFamily
                font.pixelSize: PopupConfiguration.notificationPopupHeaderFontSize

            }

            Item {
                Layout.fillWidth: true
            }

            Item {
                id: dismissItem

                implicitWidth: dismissButton.implicitWidth
                implicitHeight: dismissButton.implicitHeight

                SquaredButton {
                    id: dismissButton

                    anchors.fill: parent
                    glyph: PopupConfiguration.notificationPopupIcon.clear
                    glyphSize: PopupConfiguration.notificationPopupHeaderIconSize
                    alignWhenCentered: false
                    onLeftClicked: root.dismiss()
                    onRightClicked: root.dismiss()
                }

                CountdownRing {
                    id: countdownRing

                    anchors.centerIn: dismissItem
                    width: PopupConfiguration.notificationCountdownRingMargin + PopupConfiguration.notificationPopupHeaderIconSize
                    height: width
                    visible: (root.entry?.timeout ?? 0) > 0 && !root.entry?.popupPinned

                    strokeWidth: PopupConfiguration.notificationCountdownRingWidth
                    strokeColor: Settings.colors.foreground.muted
                    duration: root.entry?.timeout ?? 0
                    deadline: root.entry?.popupExpiresAt ?? 0
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: PopupConfiguration.notificationPopupVSpacing
            visible: (root.entry?.summary.length ?? 0) > 0
            spacing: 0

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.entry?.summary ?? ""
                textFormat: Text.PlainText
                color: Settings.colors.foreground.main
                font.family: Settings.labelFontFamily
                font.pixelSize: PopupConfiguration.notificationPopupTitleFontSize
                font.bold: true
                wrapMode: Text.Wrap
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: (root.entry?.body.length ?? 0) > 0
            spacing: 0

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.entry?.body ?? ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                color: Settings.colors.foreground.muted
                font.family: Settings.labelFontFamily
                font.pixelSize: PopupConfiguration.notificationPopupFontSize

            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: PopupConfiguration.notificationPopupVSpacing
            visible: root.hasActions || root.hasImage
            spacing: PopupConfiguration.notificationPopupAttentionHSpacing

            Flow {
                id: actions
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                layoutDirection: Qt.RightToLeft
                spacing: PopupConfiguration.notificationPopupAttentionHSpacing
                visible: root.hasActions

                Repeater {
                    id: actionButtons
                    model: root.entry?.actions?.slice().reverse() ?? []

                    Controls.Button {
                        id: actionButton

                        required property var modelData

                        width: Math.min(implicitWidth, actions.width)
                        padding: PopupConfiguration.notificationActionButtonPadding
                        text: modelData.text || "Open"

                        background: BackgroundRectangle {
                            color: actionButton.hovered ? Settings.colors.background.tint4 : Settings.colors.background.tint3
                        }

                        contentItem: Text {
                            text: actionButton.text
                            wrapMode: Text.Wrap
                            color: Settings.colors.foreground.main
                            font.family: Settings.labelFontFamily
                            font.pixelSize: PopupConfiguration.notificationPopupFontSize
                        }

                        onClicked: modelData.invoke()
                    }
                }
            }

            Image {
                id: image

                Layout.fillWidth: !root.hasActions
                Layout.minimumWidth: 0
                Layout.maximumWidth: root.hasActions ? root.availableWidth / 2 : root.availableWidth
                Layout.preferredHeight: PopupConfiguration.notificationPopupImageHeight
                visible: root.hasImage
                source: visible ? root.entry.image : ""
                fillMode: Image.PreserveAspectFit
                sourceSize.height: PopupConfiguration.notificationPopupImageHeight * PopupConfiguration.notificationPopupImageSourceScale
            }
        }
    }

    // ────── Helper Functions ──────
    function dismiss(): void {
        root.dismissEntries([root.entry])
    }

    function isOverControl(scenePosition): bool {
        if (dismissButton.contains(dismissButton.mapFromItem(null, scenePosition)))
            return true

        for (let i = 0; i < actionButtons.count; ++i) {
            const button = actionButtons.itemAt(i)
            if (button?.visible && button.contains(button.mapFromItem(null, scenePosition)))
                return true
        }

        return false
    }

    function handleTap(scenePosition, button): void {
        // Child controls keep their own clicks, including right clicks on actions.
        if (!root.entry?.alive || root.isOverControl(scenePosition))
            return

        switch (button) {
            case Qt.LeftButton:
                root.entry.popupPinned = true
                break
            case Qt.RightButton:
                root.dismiss()
                break
        }
    }

    function formattedTime(): string {
        if (!root.entry)
            return ""

        return Qt.formatDateTime(root.entry.receivedAt, "HH:mm")
    }
}
