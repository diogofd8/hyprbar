pragma Singleton

import QtQuick
import Quickshell

import qs

//
// Spotify back end.
//
// State and transport come from MPRIS, which Quickshell speaks natively: the
// player is already on the bus, so nothing has to be shelled out to find out
// what it is doing or to tell it what to do next.
//
// The marquee uses that same player state. Its timer runs only while a long
// title is playing; the bar module only draws the resulting text.
//
// Closing is MPRIS as well — Spotify reports CanQuit — and launching goes
// through its desktop entry, so neither needs a script.
//
Singleton {
    id: root

    // ────── Player ──────
    // Null whenever Spotify is closed, which is most of the time — every
    // reader below has to tolerate that.
    readonly property var player: {
        const players = Media.players
        const busName = "org.mpris.MediaPlayer2." + SpotifyConfig.playerName

        for (let i = 0; i < players.length; i++) {
            if (players[i].dbusName === busName)
                return players[i]
        }

        return null
    }

    readonly property bool running: root.player !== null
    readonly property bool playing: root.running && root.player.isPlaying

    // MPRIS properties update when the player reports new metadata. The
    // formatter below selects the fields named by the configured format.
    readonly property string title: root.running ? root.player.trackTitle : ""
    readonly property string artist: root.running ? root.player.trackArtist : ""
    readonly property string album: root.running ? root.player.trackAlbum : ""
    readonly property string albumArtist: root.running ? root.player.trackAlbumArtist : ""

    // ────── Metadata Marquee ──────
    // Treat the format as a string so separators and other literal text can
    // sit anywhere among placeholders. Keep unknown placeholders intact so
    // a typo in the configuration is visible rather than silently lost.
    function formatMetadata(format) {
        return format.replace(/%%|%([A-Za-z][A-Za-z0-9_]*)%/g, (token, key) => {
            if (token === "%%")
                return "%"

            switch (key) {
            case "title": return root.title
            case "artist": return root.artist
            case "song_separator": return root.title && root.artist
                ? SpotifyConfig.songSeparator : ""
            case "album": return root.album
            case "albumArtist": return root.albumArtist
            default: return token
            }
        })
    }

    readonly property int windowSize: Math.max(1, SpotifyConfig.metadataWindowSize)
    readonly property string formattedMetadata: {
        if (!root.running)
            return ""

        const text = root.formatMetadata(SpotifyConfig.metadataFormat)
        return SpotifyConfig.metadataUppercase ? text.toUpperCase() : text
    }

    // Array.from keeps surrogate pairs together. Build the character array
    // only when metadata changes; each timer tick assembles one small window.
    readonly property var metadataCharacters: Array.from(root.formattedMetadata)
    readonly property bool needsScroll: root.metadataCharacters.length > root.windowSize
    readonly property var scrollCharacters: root.needsScroll
        ? root.metadataCharacters.concat(Array(Math.max(0, SpotifyConfig.metadataScrollGap)).fill(" "))
        : []

    property int scrollOffset: 0

    readonly property string metadata: {
        if (!root.needsScroll)
            return root.formattedMetadata

        const characters = root.scrollCharacters
        const start = root.scrollOffset % characters.length
        const frame = []
        for (let i = 0; i < root.windowSize; i++)
            frame.push(characters[(start + i) % characters.length])
        return frame.join("")
    }

    onFormattedMetadataChanged: {
        if (SpotifyConfig.resetScrollOnTrackOrPlaybackChange)
            root.scrollOffset = 0
    }

    onPlayingChanged: {
        if (SpotifyConfig.resetScrollOnTrackOrPlaybackChange)
            root.scrollOffset = 0
    }

    // A newly opened player starts a fresh scroll even if the optional
    // reset-on-change behavior is disabled.
    onRunningChanged: {
        if (!root.running)
            root.scrollOffset = 0
    }

    Timer {
        interval: Math.max(1, SpotifyConfig.metadataScrollIntervalMs)
        repeat: true
        running: root.playing && root.needsScroll

        onTriggered: root.scrollOffset = (root.scrollOffset + 1) % root.scrollCharacters.length
    }

    // ────── Transport ──────
    // The shared service keeps the bar and centerpiece's transport behavior
    // consistent, including Spotify's correction after a skip while paused.
    function togglePlaying() {
        Media.togglePlaying(root.player)
    }

    function next() {
        Media.next(root.player)
    }

    function previous() {
        Media.previous(root.player)
    }

    Connections {
        target: root.player

        function onTrackChanged() {
            if (SpotifyConfig.resetScrollOnTrackOrPlaybackChange)
                root.scrollOffset = 0
        }
    }

    // Nothing to talk to over MPRIS until it is running, so this is the one
    // action that has to go outside: the desktop entry, with gtk-launch as a
    // fallback if the entry ever goes missing.
    function launch() {
        const entry = DesktopEntries.byId(SpotifyConfig.desktopEntry)

        if (entry)
            entry.execute()
        else
            Quickshell.execDetached(["gtk-launch", SpotifyConfig.desktopEntry])
    }

    function close() {
        Media.quit(root.player)
    }
}
