import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell

import qs
import qs.components
import qs.core as Core

import "notificationmanager" as NotificationUI

Controls.Pane {
    id: root
    signal dismissRequested()

    readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: root }

    property var service: Core.Notifications
    property bool expanded: false
    property var expandedGroups: ({})
    readonly property real maximumListHeight: availableContentHeight()

    Connections {
        target: root.service.groups
        function onCountChanged() {
            root.pruneExpandedGroups()
        }
    }

    padding: WidgetConfiguration.dropDownWindowPadding
    implicitHeight: panelContent.implicitHeight + root.topPadding + root.bottomPadding
    clip: true

    // PopoutHost supplies the shared widget background.
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

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: WidgetConfiguration.hexSwitchSpacing

                    Glyph {
                        icon: root.doNotDisturbIcon()
                        iconSize: WidgetConfiguration.widgetMainIconSz
                        iconColor: Settings.colors.foreground.main
                        useMetrics: true
                    }

                    HexagonSwitch {
                        actionable: true
                        checked: root.service.doNotDisturb
                        onClicked: root.service.doNotDisturb = !root.service.doNotDisturb

                        bgFill: Settings.colors.background.main
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Loader {
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: root.service.doNotDisturb ? dndLabel : notificationCountLabel
                }

                Item {
                    Layout.fillWidth: true
                }

                SquaredButton {
                    glyph: NotificationUI.Configuration.nfExpandIcon
                    glyphSize: WidgetConfiguration.widgetMainIconSz
                    useMetrics: true

                    enabled: list.contentHeight > NotificationUI.Configuration.notificationCompactHeight
                    opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity

                    glyphRotation: root.expanded ? 180 : 0
                    onLeftClicked: root.expanded = !root.expanded

                    Behavior on glyphRotation { Anim {} }
                }

                SquaredButton {
                    glyph: NotificationUI.Configuration.nfClearAllIcon
                    glyphSize: WidgetConfiguration.widgetMainIconSz

                    enabled: root.service.count > 0
                    opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity

                    onLeftClicked: {
                        root.clearAll()
                        root.dismissRequested()
                    }
                }
            }

            Separator {
                Layout.fillWidth: true
                Layout.topMargin: 1
                Layout.bottomMargin: WidgetConfiguration.mainRowVMargin
                color: Settings.colors.background.tint4
            }
        }

        // ────── Notifications ──────
        ListView {
            id: list

            readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: list }

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: implicitHeight
            implicitWidth: NotificationUI.Configuration.contentWidth
            implicitHeight: root.listHeight()

            clip: true
            spacing: WidgetConfiguration.sectionContentVSpacing
            model: root.service.groups
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: BackgroundScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }

            delegate: NotificationUI.NotificationCard {
                id: notificationCard

                service: root.service
                width: root.cardWidth()
                expanded: root.expandedGroups[notificationCard.group?.key ?? ""] === true
                onExpansionRequested: root.setGroupExpanded(group.key, !expanded)
            }

            ColumnLayout {
                parent: list
                anchors.centerIn: parent
                visible: root.service.count === 0
                spacing: WidgetConfiguration.sectionContentVSpacing

                Glyph {
                    Layout.alignment: Qt.AlignHCenter
                    useMetrics: false
                    icon: NotificationUI.Configuration.nfReadIcon
                    iconSize: WidgetConfiguration.widgetMainIconSz
                    iconColor: Settings.colors.foreground.muted
                }

                Text {
                    text: "No notifications"
                    color: Settings.colors.foreground.muted
                    font.family: Settings.labelFontFamily
                    font.pixelSize: WidgetConfiguration.widgetMsgFieldFontSz

                }
            }
        }
    }

    Component {
        id: dndLabel

        Text {
            text: "Do Not Disturb"
            color: Settings.colors.foreground.accent
            font.family: Settings.labelFontFamily
            font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
        }
    }

    Component {
        id: notificationCountLabel

        Text {
            visible: root.service.count > 0
            text: root.notificationCountText()
            color: Settings.colors.foreground.main
            font.family: Settings.labelFontFamily
            font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
        }
    }

    // ────── Helper Functions ──────
    function setGroupExpanded(key, expanded): void {
        const states = Object.assign({}, root.expandedGroups)

        if (expanded)
            states[key] = true
        else
            delete states[key]

        root.expandedGroups = states
    }

    function pruneExpandedGroups(): void {
        const states = {}

        for (let i = 0; i < root.service.groups.count; ++i) {
            const key = root.service.groups.get(i).group.key
            if (root.expandedGroups[key] === true)
                states[key] = true
        }

        root.expandedGroups = states
    }

    function clearAll(): void {
        const cards = []

        for (let i = 0; i < root.service.groups.count; ++i) {
            const group = root.service.groups.get(i).group
            const item = list.itemAtIndex(i)
            cards.push({group, item})
        }

        for (const card of cards) {
            if (card.item)
                card.item.dismiss()
            else
                root.service.dismissGroup(card.group)
        }
    }

    function availableContentHeight(): real {
        const window = root.QsWindow.window
        const windowHeight = window ? window.screen.height : Infinity
        const maxPopoutHeight = Math.min(Settings.popoutHostHeight, windowHeight)

        const availableHeight = maxPopoutHeight - Settings.barHeight
        const padding = root.topPadding + root.bottomPadding
        const reservedHeight = headerContainer.implicitHeight + panelContent.spacing

        return Math.max(0, availableHeight - padding - reservedHeight)
    }

    function doNotDisturbIcon(): string {
        const icons = NotificationUI.Configuration.nfDoNotDisturbIcon
        return root.service.doNotDisturb ? icons.on : icons.off
    }

    function listHeight(): real {
        const compactHeight = NotificationUI.Configuration.notificationCompactHeight
        let height = compactHeight

        if (root.service.count !== 0) {
            if (root.expanded)
                height = list.contentHeight
            else
                height = Math.min(list.contentHeight, compactHeight)
        }

        return Math.min(root.maximumListHeight, height)
    }

    function cardWidth(): real {
        if (list.contentHeight > list.height)
            return list.width - NotificationUI.Configuration.nfScrollBarReserve

        return list.width
    }

    function notificationCountText(): string {
        const count = root.service.count
        return count + (count === 1 ? " notification" : " notifications")
    }
}
