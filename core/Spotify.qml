pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

//
// Spotify back end.
//
// State and transport come from MPRIS, which Quickshell speaks natively: the
// player is already on the bus, so nothing has to be shelled out to find out
// what it is doing or to tell it what to do next.
//
// The one thing MPRIS has no notion of is the marquee, so that stays the job
// of the scripts/spotify_module binary — consumed here purely as a source of
// text, with the glyphs it can also emit left unused.
//
// Closing is MPRIS as well — Spotify reports CanQuit — and launching goes
// through its desktop entry, so neither needs a script. 
//
Singleton {
    id: root

    // ────── Configuration ──────
    // Deliberately here rather than in Settings: this module is meant to be
    // self-contained, so deleting core/Spotify.qml and modules/Spotify.qml
    // takes every trace of it with them.
    readonly property string playerName: "spotify"
    readonly property string desktopEntry: "spotify"

    readonly property string metadataFormat: "%title%%song_separator%%artist%%suffix%"
    readonly property int scrollerWindowSize: 8
    readonly property int scrollerIntervalMs: 200
    readonly property bool scrollerCapsLock: true

    // Spotify starts playing whenever it changes track, even from a pause.
    // Skipping should not start the music, so the player is put back on pause
    // when this is on. The guard is how long that correction stays armed.
    readonly property bool keepPausedOnSkip: true
    readonly property int skipPauseGuardMs: 2000

    // ────── Player ──────
    // Null whenever Spotify is closed, which is most of the time — every
    // reader below has to tolerate that.
    readonly property var player: {
        const players = Mpris.players.values
        const busName = "org.mpris.MediaPlayer2." + root.playerName

        for (let i = 0; i < players.length; i++) {
            if (players[i].dbusName === busName)
                return players[i]
        }

        return null
    }

    readonly property bool running: root.player !== null
    readonly property bool playing: root.running && root.player.isPlaying

    // Raw fields, for anything that wants the untrimmed text later.
    readonly property string title: root.running ? root.player.trackTitle : ""
    readonly property string artist: root.running ? root.player.trackArtist : ""

    // ────── Metadata Marquee ──────
    // Last frame the scroller printed. Blanked through `metadata` rather than
    // here, so a closed player cannot leave its final frame on the bar.
    property string scrollFrame: ""

    readonly property string metadata: root.running ? root.scrollFrame : ""

    // ────── Transport ──────
    // Guarded rather than disabled at the call site: a click landing in the
    // gap between Spotify quitting and the bar noticing is a no-op, not an
    // error on a null player.
    function togglePlaying() {
        if (!root.running)
            return

        // An explicit play is exactly what the correction below must not
        // undo, so asking for one disarms it.
        root.disarmSkipPause()
        root.player.togglePlaying()
    }

    function next() {
        if (!root.running)
            return

        root.armSkipPause()
        root.player.next()
    }

    function previous() {
        if (!root.running)
            return

        root.armSkipPause()
        root.player.previous()
    }

    // ────── Skipping While Paused ──────
    // Spotify starts playing whenever it is told to change track, even from a
    // paused state — that is the player's behaviour, not something MPRIS asks
    // for. Skipping ahead to see what is next should leave the music where it
    // was, so a skip taken while paused arms this and the player goes back on
    // pause the moment it reports playing.
    //
    // It has to be a reaction rather than a pause sent straight after the
    // skip: the track change and the state change arrive in their own time,
    // and a pause sent before Spotify has started is simply lost.
    property bool holdPaused: false

    function armSkipPause() {
        if (!root.keepPausedOnSkip || root.playing)
            return

        root.holdPaused = true
        skipPauseGuard.restart()
    }

    function disarmSkipPause() {
        root.holdPaused = false
        skipPauseGuard.stop()
    }

    Connections {
        target: root.player

        function onIsPlayingChanged() {
            if (root.holdPaused && root.player.isPlaying)
                root.player.pause()
        }
    }

    // Without this the correction would outlive the skip that armed it, and
    // a play pressed a minute later would be swatted back down.
    Timer {
        id: skipPauseGuard

        interval: root.skipPauseGuardMs

        onTriggered: root.holdPaused = false
    }

    // Nothing to talk to over MPRIS until it is running, so this is the one
    // action that has to go outside: the desktop entry, with gtk-launch as a
    // fallback if the entry ever goes missing.
    function launch() {
        const entry = DesktopEntries.byId(root.desktopEntry)

        if (entry)
            entry.execute()
        else
            Quickshell.execDetached(["gtk-launch", root.desktopEntry])
    }

    function close() {
        if (root.running)
            root.player.quit()
    }

    // The scroller is a long-lived MPRIS listener in its own right: it prints
    // nothing until a player appears and picks straight back up when one
    // does, so it runs for the life of the shell rather than being started
    // and stopped alongside Spotify.
    Process {
        running: true

        command: [
            Quickshell.shellPath("scripts/spotify_module"),
            "--player", root.playerName,
            "--metadata-format", root.metadataFormat,
            "--window-size", String(root.scrollerWindowSize),
            "--scroller-interval", String(root.scrollerIntervalMs)
        ].concat(root.scrollerCapsLock ? ["--capslock-mode"] : [])

        stdout: SplitParser {
            onRead: data => root.scrollFrame = data
        }
    }
}
