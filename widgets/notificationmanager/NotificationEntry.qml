import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell.Services.Notifications

import qs
import qs.components
import qs.widgets

NotificationSurface {
    id: root

    required property var entry
    property bool expandedMode: false
    property bool expanded: false
    readonly property bool bodyClipped: isBodyClipped()
    readonly property bool hasActions: (entry?.actions.length ?? 0) > 0
    readonly property bool canExpand: expandedMode && (bodyClipped || hasActions)
    readonly property bool showDetails: canExpand && expanded
    readonly property bool showExtras: extrasShown()
    property real detailProgress: showDetails ? 1.0 : 0.0

    signal cardExpansionRequested()

    Behavior on detailProgress { Anim {} }

    TapHandler {
        parent: root
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => root.handleTap(button)
    }

    onEntryChanged: root.expanded = false
    onCanExpandChanged: {
        if (!root.canExpand)
            root.expanded = false
    }

    padding: 0
    leftPadding: root.entry?.urgency === NotificationUrgency.Critical ? WidgetConfiguration.entryIconHPadding : 0
    topPadding: WidgetConfiguration.entryVPadding
    bottomPadding: WidgetConfiguration.entryVPadding
    implicitHeight: contents.implicitHeight + topPadding + bottomPadding
    clip: true

    background: Item {
        Rectangle {
            width: Configuration.nfAttentionBarWidth
            height: parent.height
            color: Settings.colors.accentError
            visible: root.entry?.urgency === NotificationUrgency.Critical
        }
    }

    contentItem: ColumnLayout {
        id: contents

        spacing: WidgetConfiguration.entryRowVSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: WidgetConfiguration.mainRowHSpacing

            Item {
                id: summaryLine

                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: root.expandedMode ? summaryLine.implicitWidth : Infinity
                implicitWidth: root.expandedMode ? Math.ceil(title.implicitWidth) : 0
                implicitHeight: Math.max(title.implicitHeight, compactBody.implicitHeight)

                Text {
                    id: title

                    anchors.verticalCenter: parent.verticalCenter
                    width: root.titleWidth()

                    text: root.entry?.summary ?? ""
                    textFormat: Text.PlainText
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    id: compactBody

                    anchors.left: title.right
                    anchors.right: parent.right
                    anchors.leftMargin: title.text.length > 0 ? WidgetConfiguration.mainRowHSpacing : 0
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.expandedMode && (root.entry?.body.length ?? 0) > 0
                    text: (root.entry?.body ?? "").replace(/\s*\n\s*/g, " ")
                    textFormat: Text.StyledText
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                    opacity: Settings.colors.dimOpacity
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }
            }

            Text {
                visible: root.expandedMode
                text: root.receivedTime()
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                opacity: Settings.colors.dimOpacity
            }

            Item {
                visible: root.expandedMode
                Layout.fillWidth: true
            }

            SquaredButton {
                visible: root.expandedMode
                enabled: root.canExpand
                rotation: root.expanded ? 180 : 0
                opacity: root.canExpand ? 1 : Settings.colors.disabledOpacity

                glyph: Configuration.nfExpandIcon
                glyphSize: WidgetConfiguration.entryRowSecondaryIconSz

                onLeftClicked: root.expanded = !root.expanded
                onRightClicked: root.dismiss()

                Behavior on glyphRotation { Anim {} }
            }

            SquaredButton {
                visible: root.expandedMode
                glyph: Configuration.nfReadIcon
                glyphSize: WidgetConfiguration.entryRowSecondaryIconSz

                onLeftClicked: root.dismiss()
                onRightClicked: root.dismiss()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.bodyRowVisible()

            ColumnLayout {
                Layout.fillWidth: true
                spacing: WidgetConfiguration.sectionContentVSpacing

                Item {
                    id: bodyViewport

                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    visible: (root.entry?.body.length ?? 0) > 0
                    implicitHeight: root.bodyHeight()
                    readonly property bool revealing: root.showDetails || root.detailProgress > 0
                    clip: true

                    // Both layouts use the entry width immediately, including during creation.
                    Text {
                        id: bodyPreview

                        width: root.availableWidth
                        visible: !bodyViewport.revealing
                        text: root.entry?.body ?? ""
                        textFormat: Text.StyledText
                        color: Settings.colors.fgMain
                        font.family: Settings.labelFontFamily
                        font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                        opacity: Settings.colors.dimOpacity
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Text {
                        id: fullBody

                        width: bodyPreview.width
                        visible: bodyViewport.revealing
                        text: bodyPreview.text
                        textFormat: bodyPreview.textFormat
                        font: bodyPreview.font
                        color: bodyPreview.color
                        opacity: bodyPreview.opacity
                        wrapMode: Text.Wrap
                    }
                }

                CollapsibleRow {
                    id: imageRow

                    Layout.fillWidth: true
                    shown: root.showExtras && (root.entry?.image.length ?? 0) > 0

                    Image {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Configuration.notificationImageHeight
                        source: imageRow.visible ? root.entry?.image ?? "" : ""
                        fillMode: Image.PreserveAspectFit
                        sourceSize.height: Configuration.notificationImageHeight * Configuration.nfImageSourceScale
                    }
                }
            }
        }

        CollapsibleRow {
            Layout.fillWidth: true
            shown: root.showDetails && root.hasActions

            Flow {
                Layout.fillWidth: true
                spacing: WidgetConfiguration.entryExtendedRowHSpacing

                Repeater {
                    model: root.entry?.actions ?? []

                    Controls.Button {
                        id: actionButton

                        required property var modelData

                        text: modelData.text || "Open"
                        padding: WidgetConfiguration.entryHPadding
                        onClicked: modelData.invoke()

                        background: Rectangle {
                            color: actionButton.hovered ? Settings.colors.bgTint4 : Settings.colors.bgTint3
                        }

                        contentItem: Text {
                            text: actionButton.text
                            color: Settings.colors.fgMain
                            font.family: Settings.labelFontFamily
                            font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
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

    function handleTap(button): void {
        switch (button) {
            case Qt.RightButton:
                root.dismiss()
                break
            case Qt.LeftButton:
                if (!root.expandedMode)
                    root.cardExpansionRequested()
                else if (root.canExpand)
                    root.expanded = !root.expanded
                break
        }
    }

    function isBodyClipped(): bool {
        if (bodyPreview.width <= 0)
            return false

        const wraps = fullBody.implicitHeight > bodyPreview.implicitHeight
        return wraps || bodyPreview.truncated
    }

    function extrasShown(): bool {
        if (!root.expandedMode || bodyPreview.width <= 0)
            return false

        return !root.bodyClipped || root.showDetails
    }

    function titleWidth(): real {
        if (root.expandedMode || !compactBody.visible)
            return summaryLine.width

        const maximum = summaryLine.width * Configuration.nfCompactTitleBodyRatio
        return Math.min(title.implicitWidth, maximum)
    }

    function receivedTime(): string {
        if (!root.entry)
            return ""

        return Qt.formatDateTime(root.entry.receivedAt, "HH:mm")
    }

    function bodyRowVisible(): bool {
        if (!root.expandedMode)
            return false
        if ((root.entry?.body.length ?? 0) > 0)
            return true

        return root.showExtras && (root.entry?.image.length ?? 0) > 0
    }

    function bodyHeight(): real {
        const compactHeight = bodyPreview.implicitHeight
        const extraHeight = fullBody.implicitHeight - compactHeight
        return compactHeight + root.detailProgress * extraHeight
    }
}
