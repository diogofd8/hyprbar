import QtQuick

import qs
import qs.components
import qs.core as Core

Chevron {
    id: root

    contentLeftPadding: 1
    contentRightPadding: 1

    leftCap: Core.ChevronGeometry.Cap.Point
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: root.brandColor

    // ────── Brand ──────
    // Spotify green is the player's colour, not a role in the palette, so it
    // lives with the module and follows the theme on its own.
    readonly property color brandColor: Settings.darkMode ? "#2AB14C" : "#249C43"

    // ────── Icons ──────
    // Kept with the module rather than in Settings, so this file and
    // core/Spotify.qml are the whole of Spotify: delete the two and nothing
    // is left behind to clean up.
    readonly property string logoIcon: "󰓇"
    readonly property string playIcon: "󰐌"
    readonly property string pauseIcon: "󰏥"
    readonly property string previousIcon: "󰙣"
    readonly property string nextIcon: "󰙡"

    // ────── State ──────
    // Read-only: the player owns all of this now, so the view cannot drift
    // out of step with what Spotify is actually doing. Collapsed to the logo
    // while it is closed, transport row once it is open.
    readonly property bool isOpen: Core.Spotify.running
    readonly property bool isPlaying: Core.Spotify.playing

    // ────── Transport Controls ──────
    // One look for every button in the row: dark-on-green, and no vertical
    // offset because these glyphs are already centred at this size.
    component PlayerButton: GlyphButton {
        iconSize: Settings.buttonFontSize
        iconColor: Settings.colors.fgDark
        verticalOffset: 0
    }

    PlayerButton {
        visible: !root.isOpen

        text: root.logoIcon

        onLeftClicked: Core.Spotify.launch()
    }

    Row {
        visible: root.isOpen
        spacing: 8

        // One button rather than a play and a pause stacked under opposite
        // visibility: the row keeps its width across a play/pause, so the
        // chevron does not twitch on every toggle.
        PlayerButton {
            text: root.isPlaying
                ? root.pauseIcon
                : root.playIcon

            onLeftClicked: Core.Spotify.togglePlaying()
            onRightClicked: Core.Spotify.close()
        }

        PlayerButton {
            text: root.previousIcon

            onLeftClicked: Core.Spotify.previous()
        }

        // Reserves the whole scroller window up front. The marquee replaces
        // its text several times a second, and a box that sized itself to
        // each frame would shove the chevron — and every module left of it —
        // sideways at the same rate.
        Item {
            property int padding: 4

            implicitWidth:
                Core.Spotify.scrollerWindowSize * metadataMetrics.averageCharacterWidth
                + padding

            implicitHeight: metadata.implicitHeight

            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Settings.inducedVerticalOffset

            Text {
                id: metadata

                anchors.horizontalCenter: parent.horizontalCenter

                text: Core.Spotify.metadata
                color: Settings.colors.fgDark
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize
                font.weight: Font.Bold
            }

            FontMetrics {
                id: metadataMetrics

                font: metadata.font
            }
        }

        PlayerButton {
            text: root.nextIcon

            onLeftClicked: Core.Spotify.next()
        }
    }
}
