import QtQuick
import QtQuick.Layouts

import qs
import qs.components
import qs.widgets

NotificationSurface {
    id: root

    required property var group
    property bool expanded: false
    property real expansionProgress: expanded ? 1.0 : 0.0
    readonly property var entryItems: currentEntryItems()

    signal expansionRequested()

    Behavior on expansionProgress { Anim {} }

    onExpandedChanged: root.resetEntries()

    // Keep a child's swipe alive until it commits the dismissal.
    enabled: root.canInteract()

    TapHandler {
        parent: root
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => root.handleTap(eventPoint.scenePosition, button)
    }

    // ────── Dimensioning ──────
    leftPadding: WidgetConfiguration.entryHPadding
    rightPadding: WidgetConfiguration.entryHPadding
    topPadding: WidgetConfiguration.entryVPadding
    bottomPadding: WidgetConfiguration.entryVPadding
    implicitHeight: contents.implicitHeight + topPadding + bottomPadding
    clip: true

    background: Rectangle {
        color: Settings.colors.bgTint1
    }

    contentItem: ColumnLayout {
        id: contents

        spacing: WidgetConfiguration.sectionContentVSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: WidgetConfiguration.mainRowHSpacing

            NotificationAppIcon {
                iconSize: WidgetConfiguration.entryRowMainIconSz
                source: root.group?.latest?.appIcon ?? ""
                desktopEntry: root.group?.latest?.desktopEntry ?? ""
                appName: root.group?.latest?.appName ?? ""
            }

            Text {
                Layout.minimumWidth: 0
                text: root.group?.latest?.appName ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: WidgetConfiguration.entryRowTitleFontSz
                font.bold: true
            }

            Text {
                visible: !root.expanded
                text: root.receivedTime()
                color: Settings.colors.fgMain
                font.family: Settings.labelFontFamily
                font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                opacity: Settings.colors.dimOpacity
            }

            Item {
                Layout.fillWidth: true
            }

            SquaredButton {
                rotation: root.expanded ? 180 : 0
                glyph: Configuration.nfExpandIcon
                glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                color: Settings.colors.fgMain

                onLeftClicked: root.expansionRequested()
                onRightClicked: root.dismiss()

                Behavior on glyphRotation { Anim {} }
            }

            RowLayout {
                spacing: WidgetConfiguration.entryTitleRowHSpacing

                Text {
                    text: root.group?.count ?? 0
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.entryRowDefaultFontSz
                    opacity: Settings.colors.dimOpacity
                }

                SquaredButton {
                    glyph: Configuration.nfClearAllIcon
                    glyphSize: WidgetConfiguration.entryRowSecondaryIconSz
                    color: Settings.colors.fgMain

                    onLeftClicked: root.dismiss()
                    onRightClicked: root.dismiss()
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: root.entriesHeight()
            clip: true

            Loader {
                id: compactLoader

                width: parent.width
                active: (root.group?.count ?? 0) > 0
                visible: !entryLoader.active
                sourceComponent: compactEntries
            }

            Loader {
                id: entryLoader

                width: parent.width
                // Keep the full contents laid out until the closing reveal finishes.
                active: root.expandedEntriesActive()
                enabled: root.expanded
                sourceComponent: expandedEntries
            }
        }
    }

    Component {
        id: compactEntries

        ColumnLayout {
            spacing: WidgetConfiguration.sectionContentVSpacing

            Repeater {
                model: root.group?.model ?? null

                NotificationEntry {
                    Layout.fillWidth: true
                    service: root.service
                    onCardExpansionRequested: root.expansionRequested()
                }
            }
        }
    }

    Component {
        id: expandedEntries

        ColumnLayout {
            spacing: WidgetConfiguration.sectionContentVSpacing

            Repeater {
                model: root.group?.model ?? null

                NotificationEntry {
                    Layout.fillWidth: true
                    service: root.service
                    expandedMode: true
                }
            }
        }
    }

    // ────── Helper Functions ──────
    function currentEntryItems(): var {
        const item = entryLoader.item ?? compactLoader.item

        if (!item)
            return []

        return item.children.filter(child => child.entry !== undefined)
    }

    function resetEntries(): void {
        if (root.expanded) {
            for (const item of root.entryItems)
                item.expanded = false
        }
    }

    function canInteract(): bool {
        if (root.dismissing)
            return false

        return !root.entryItems.some(item => item.dismissing)
    }

    function dismiss(): void {
        const entries = []

        for (let i = 0; i < (root.group?.model.count ?? 0); ++i)
            entries.push(root.group.model.get(i).entry)

        root.dismissEntries(entries)
    }

    function isOverEntry(scenePosition): bool {
        for (const item of root.entryItems) {
            const position = item.mapFromItem(null, scenePosition)
            if (item.contains(position))
                return true
        }

        return false
    }

    function handleTap(scenePosition, button): void {
        // Entries handle their own expansion and dismissal.
        if (root.isOverEntry(scenePosition))
            return

        switch (button) {
            case Qt.RightButton:
                root.dismiss()
                break
            case Qt.LeftButton:
                root.expansionRequested()
                break
        }
    }

    function receivedTime(): string {
        if (!root.group?.latest)
            return ""

        return Qt.formatDateTime(root.group.latest.receivedAt, "HH:mm")
    }

    function entriesHeight(): real {
        const compactHeight = compactLoader.implicitHeight
        const extraHeight = entryLoader.implicitHeight - compactHeight
        return compactHeight + root.expansionProgress * extraHeight
    }

    function expandedEntriesActive(): bool {
        const hasEntries = (root.group?.count ?? 0) > 0
        return hasEntries && (root.expanded || root.expansionProgress > 0)
    }
}
