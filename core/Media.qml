pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

import qs

Singleton {
    id: root

    // playerctld mirrors another player rather than providing another source.
    readonly property var players: Mpris.players.values.filter(player =>
        player.dbusName !== "org.mpris.MediaPlayer2.playerctld")
    property string selectedPlayerName: ""
    readonly property var activePlayer: root.players.find(player =>
        player.dbusName === root.selectedPlayerName) ?? null

    onPlayersChanged: {
        if (!root.players.some(player => player.dbusName === root.selectedPlayerName)) {
            const fallback = root.players.find(player => player.isPlaying) ?? root.players[0]
            root.selectedPlayerName = fallback?.dbusName ?? ""
        }
        if (root.pausedSkipPlayer && !root.players.includes(root.pausedSkipPlayer))
            root.disarmSkipPause(root.pausedSkipPlayer)
    }

    function selectPlayer(player): void {
        if (root.players.includes(player))
            root.selectedPlayerName = player.dbusName
    }

    // An optional target lets the Spotify bar keep controlling Spotify even
    // when the centerpiece is displaying a different player.
    function togglePlaying(player = root.activePlayer): void {
        if (!player?.canControl || !player.canTogglePlaying)
            return
        root.disarmSkipPause(player)
        player.togglePlaying()
    }

    function next(player = root.activePlayer): void {
        if (!player?.canControl || !player.canGoNext)
            return
        root.armSkipPause(player)
        player.next()
    }

    function previous(player = root.activePlayer): void {
        if (!player?.canControl || !player.canGoPrevious)
            return
        root.armSkipPause(player)
        player.previous()
    }

    function seekTo(player, seconds: real): void {
        if (player?.canControl && player.canSeek && player.positionSupported
                && player.lengthSupported && player.length > 0 && Number.isFinite(seconds))
            player.position = Math.max(0, Math.min(seconds, player.length))
    }

    function quit(player = root.activePlayer): void {
        if (!player?.canQuit)
            return
        root.disarmSkipPause(player)
        player.quit()
    }

    // Spotify can resume on a skip requested while paused. Share its existing
    // correction between both UIs, and bind it to that player rather than the
    // current selection, which can change while the reply is in flight.
    property MprisPlayer pausedSkipPlayer: null

    function armSkipPause(player): void {
        if (player.dbusName !== "org.mpris.MediaPlayer2." + SpotifyConfig.playerName
                || !SpotifyConfig.keepPausedOnSkip || player.isPlaying || !player.canPause)
            return
        root.pausedSkipPlayer = player
        skipPauseGuard.restart()
    }

    function disarmSkipPause(player): void {
        if (root.pausedSkipPlayer !== player)
            return
        root.pausedSkipPlayer = null
        skipPauseGuard.stop()
    }

    Connections {
        target: root.pausedSkipPlayer

        function onIsPlayingChanged(): void {
            const player = root.pausedSkipPlayer
            if (player?.isPlaying && player.canControl && player.canPause)
                player.pause()
        }
    }

    Timer {
        id: skipPauseGuard
        interval: SpotifyConfig.skipPauseGuardMs
        onTriggered: root.pausedSkipPlayer = null
    }
}
