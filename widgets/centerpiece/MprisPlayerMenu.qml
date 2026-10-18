import QtQuick
import QtQuick.Controls.Basic

import qs
import qs.components

Popup {
    id: root

    required property Item anchorItem
    required property var players
    required property var selectedPlayer
    readonly property int selectedIndex: root.players.indexOf(root.selectedPlayer)
    signal playerSelected(var player)
    property bool closing: false
    property real horizontalProgress: 0
    property real verticalProgress: 0
    readonly property Item buttonParent: buttonArea
    readonly property bool anchorActive: root.anchorItem.visible && root.anchorItem.enabled

    onSelectedIndexChanged: {
        if (root.opened)
            playerList.currentIndex = root.selectedIndex
    }

    onPlayersChanged: {
        if (root.players.length === 0)
            root.close()
    }

    parent: root.anchorItem
    x: 0
    y: 0
    width: root.anchorItem.width
        + (Configuration.mprisPlayerMenuWidth - root.anchorItem.width) * root.horizontalProgress
    height: root.anchorItem.height
        + (implicitHeight - root.anchorItem.height) * root.verticalProgress
    padding: 0
    margins: Configuration.mprisPlayerMenuPadding
    clip: true

    popupType: Popup.Item
    modal: true
    dim: false
    focus: true
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

    onAboutToShow: root.closing = false
    onAboutToHide: root.closing = true
    onClosed: root.closing = false

    Connections {
        target: root.anchorItem

        function onVisibleChanged(): void {
            if (!root.anchorItem.visible)
                root.close()
        }

        function onEnabledChanged(): void {
            if (!root.anchorItem.enabled)
                root.close()
        }
    }

    onOpened: {
        playerList.currentIndex = root.selectedIndex
        playerList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        playerList.forceActiveFocus()
    }

    function selectPlayer(player): void {
        if (root.players.includes(player))
            root.playerSelected(player)
        root.close()
    }

    background: BackgroundSurface {
        id: menuBackground
        Rectangle { anchors.fill: parent; color: Settings.colors.background.tint2 }
    }

    contentItem: Item {
        readonly property Item backgroundTarget: menuBackground.paintTarget
        implicitWidth: Configuration.mprisPlayerMenuWidth
        implicitHeight: root.anchorItem.height + 2 * Configuration.mprisPlayerMenuPadding
            + playerList.implicitHeight

        Item {
            id: buttonArea
            readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: buttonArea }
            width: root.anchorItem.width
            height: root.anchorItem.height
            z: 1
        }

        ListView {
            id: playerList

            readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: playerList }
            readonly property real scrollbarGutter: playerScrollbar.visible ? playerScrollbar.width : 0
            readonly property int visibleEntryCount:
                Math.min(count, Math.max(1, Configuration.mprisPlayerMenuMaxVisibleEntries))

            implicitHeight: visibleEntryCount * Configuration.mprisPlayerMenuEntryHeight
                + Math.max(0, visibleEntryCount - 1) * spacing

            x: Configuration.mprisPlayerMenuPadding + scrollbarGutter
            y: root.anchorItem.height + Configuration.mprisPlayerMenuPadding
            // Keep entries at their final size while the popup clips the reveal.
            width: Math.max(0, Configuration.mprisPlayerMenuWidth
                - 2 * Configuration.mprisPlayerMenuPadding - scrollbarGutter)
            height: implicitHeight
            enabled: root.opened

            clip: true
            model: root.players
            spacing: Configuration.mprisPlayerMenuEntrySpacing
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            keyNavigationEnabled: true
            keyNavigationWraps: true

            Keys.onReturnPressed: root.selectPlayer(root.players[currentIndex])
            Keys.onEnterPressed: root.selectPlayer(root.players[currentIndex])
            Keys.onSpacePressed: root.selectPlayer(root.players[currentIndex])

            delegate: ItemDelegate {
                id: entry
                required property int index
                required property var modelData

                width: ListView.view.width
                height: Configuration.mprisPlayerMenuEntryHeight
                padding: Configuration.mprisPlayerMenuPadding
                highlighted: index === root.selectedIndex
                hoverEnabled: true

                onClicked: root.selectPlayer(entry.modelData)

                HoverHandler {
                    enabled: entry.enabled
                    cursorShape: Qt.PointingHandCursor
                }

                background: BackgroundRectangle {
                    color: entry.down || entry.hovered || entry.activeFocus ? Settings.colors.background.tint4
                        : entry.highlighted ? Settings.colors.background.tint3 : "transparent"
                }

                contentItem: Text {
                    text: entry.modelData.identity || entry.modelData.dbusName.replace("org.mpris.MediaPlayer2.", "")
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.mprisPlayerMenuEntryFontSz
                    color: Settings.colors.foreground.main
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            ScrollBar.vertical: ScrollBar {
                id: playerScrollbar
                // Use explicit geometry instead of the attached bar's automatic placement.
                parent: playerList.parent
                anchors.right: playerList.left
                anchors.top: playerList.top
                anchors.bottom: playerList.bottom
                width: Configuration.mprisPlayerMenuScrollbarWidth
                visible: playerList.interactive
                enabled: playerList.enabled
                policy: ScrollBar.AsNeeded

                contentItem: BackgroundRectangle {
                    implicitWidth: Configuration.mprisPlayerMenuScrollbarWidth
                    radius: width / 2
                    color: Settings.colors.background.highlight
                    opacity: parent.active ? 1 : Settings.colors.background.dimOpacity
                }

                background: BackgroundRectangle {
                    color: Settings.colors.background.tint2
                }
            }
        }
    }

    enter: Transition {
        SequentialAnimation {
            Anim {
                target: root
                property: "horizontalProgress"
                to: 1
                duration: root.anchorActive ? Motion.fastMs / 2 : 0
            }

            Anim {
                target: root
                property: "verticalProgress"
                to: 1
                duration: root.anchorActive ? Motion.normalMs / 2 : 0
            }
        }
    }

    exit: Transition {
        SequentialAnimation {
            Anim {
                target: root
                property: "verticalProgress"
                to: 0
                duration: root.anchorActive ? Motion.normalMs / 2 : 0
            }

            Anim {
                target: root
                property: "horizontalProgress"
                to: 0
                duration: root.anchorActive ? Motion.fastMs / 2 : 0
            }
        }
    }
}
