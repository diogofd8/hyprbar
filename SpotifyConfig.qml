pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // ────── Player ──────
    readonly property string playerName: "spotify"
    readonly property string desktopEntry: "spotify"

    // ────── Metadata ──────
    // Literal text is kept as written. These placeholders map to MPRIS
    // metadata fields: %title%, %artist%, %album%, and %albumArtist%.
    // %song_separator% expands only when both title and artist are present.
    // Use %% for a literal percent sign; unknown placeholders stay visible.
    readonly property string metadataFormat: "%title%%song_separator%%artist%"
    // Include the surrounding spaces so they disappear with the separator.
    readonly property string songSeparator: " - "
    readonly property bool metadataUppercase: true
    readonly property int metadataWindowSize: 8
    readonly property int metadataScrollIntervalMs: 250 // Smaller is faster.
    // Number of blank characters between the end and start of the marquee.
    readonly property int metadataScrollGap: 2
    // When false, a pause keeps its scroll position and a new track inherits it.
    readonly property bool resetScrollOnTrackOrPlaybackChange: true

    // ────── Transport ──────
    // Spotify can start playing after a skip requested while paused. Briefly
    // guard that transition and put it back on pause when enabled.
    readonly property bool keepPausedOnSkip: true
    readonly property int skipPauseGuardMs: 2000

    // ────── Bar Appearance ──────
    readonly property string logoIcon: "󰓇"
    readonly property string playIcon: "󰐌"
    readonly property string pauseIcon: "󰏥"
    readonly property string previousIcon: "󰙣"
    readonly property string nextIcon: "󰙡"

    readonly property real leftSidePadding: 1
    readonly property real rightSidePadding: 1
    readonly property int transportSpacing: 8
    readonly property int metadataWidthPadding: 4
}
