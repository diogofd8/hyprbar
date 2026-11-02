import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

import qs
import qs.core as Core
import qs.components
import qs.widgets as Widgets

Pane {
    id: root

    background: null
    // ────── Dimensioning ──────
    topPadding: Configuration.pagePadding - Widgets.WidgetConfiguration.dropDownWindowPadding
    bottomPadding: Configuration.pagePadding
    horizontalPadding: Configuration.pagePadding

    contentItem: Item {
        id: mprisPlayer

        readonly property var player: Core.Media.activePlayer
        readonly property real trackLength: mprisPlayer.readTrackLength()
        readonly property real position: mprisPlayer.readPosition()
        readonly property bool seekable: mprisPlayer.canSeek()

        implicitWidth: mprisContainer.implicitWidth
        implicitHeight: mprisContainer.implicitHeight

        // This page owns capture demand. A Binding does not restore its value when
        // destroyed, so explicitly release demand when the page's Loader unloads it.
        Component.onDestruction: Core.Cava.active = false

        Binding {
            target: Core.Cava
            property: "active"
            value: mprisPlayer.visible && !!mprisPlayer.player?.isPlaying
        }

        Binding {
            target: Core.Cava
            property: "barCount"
            value: Configuration.mprisVisualizerBarCount
        }

        Binding {
            target: Core.Cava
            property: "frameRate"
            value: Configuration.mprisVisualizerFrameRate
        }

        // Quickshell extrapolates position locally; this only refreshes bindings,
        // without polling the player over D-Bus or ticking while the page is hidden.
        Timer {
            interval: mprisPlayer.positionRefreshInterval()
            repeat: true
            running: mprisPlayer.visible && !!mprisPlayer.player?.isPlaying && mprisPlayer.player.positionSupported
            onTriggered: mprisPlayer.player.positionChanged()
        }

        onPlayerChanged: mprisPlayer.refreshPosition()
        onVisibleChanged: mprisPlayer.refreshVisiblePosition()

        MprisPlayerMenu {
            id: playerMenu
            anchorItem: activePlayerSlot
            players: Core.Media.players
            selectedPlayer: mprisPlayer.player
            onPlayerSelected: player => Core.Media.selectPlayer(player)
        }

        ColumnLayout {
            id: mprisContainer
            anchors.fill: parent
            spacing: 0

            RowLayout {
                spacing: 0

                Item {
                    id: activePlayerSlot
                    enabled: Core.Media.players.length > 0
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Configuration.mprisHMargin
                    Layout.leftMargin: Configuration.mprisHMargin
                    // Preserve the layout slot while the button is in the menu overlay.
                    implicitWidth: activePlayerBtn.implicitWidth
                    implicitHeight: activePlayerBtn.implicitHeight

                    ChevronButton {
                        id: activePlayerBtn
                        parent: playerMenu.visible ? playerMenu.buttonParent : activePlayerSlot
                        anchors.fill: parent
                        visible: activePlayerSlot.visible
                        enabled: activePlayerSlot.enabled
                        contentLeftPadding: Configuration.mprisActionBtnPaddingL
                        contentRightPadding: Configuration.mprisActionBtnPaddingS

                        leftCap: Core.ChevronGeometry.Cap.Flat
                        rightCap: Core.ChevronGeometry.Cap.Point

                        bgFill: Settings.colors.background.tint2

                        onLeftClicked: mprisPlayer.togglePlayerMenu()

                        Glyph {
                            icon: Configuration.mprisActionBtn.source
                            iconSize: Configuration.mprisPrevNextBtnSz
                            iconColor: Settings.colors.foreground.main
                            verticalOffset: 0
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    id: mprisArtContainer
                    Layout.topMargin: Configuration.mprisArtPaddingY
                    Layout.bottomMargin: Configuration.mprisArtPaddingY
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: mprisArt.width
                    implicitHeight: mprisArt.height

                    MprisSpectrum {
                        anchors.centerIn: mprisArt
                        anchors.alignWhenCentered: false
                        barCount: Core.Cava.outputBarCount
                        levels: Core.Cava.levels
                    }

                    ClippingRectangle {
                        id: mprisArt
                        anchors.centerIn: parent
                        width: Configuration.mprisArtImgSz
                        height: width
                        radius: width / 2
                        color: "transparent"

                        BackgroundRectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Settings.colors.background.imagePlaceholder
                        }

                        Image {
                            id: albumArt
                            anchors.fill: parent
                            source: mprisPlayer.player?.trackArtUrl ?? ""
                            sourceSize.width: Configuration.mprisArtImgSz * Screen.devicePixelRatio
                            sourceSize.height: Configuration.mprisArtImgSz * Screen.devicePixelRatio
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Glyph {
                            anchors.centerIn: parent
                            visible: albumArt.status !== Image.Ready
                            icon: Configuration.mprisActionBtn.source
                            iconSize: Configuration.mprisArtImgSz / 2
                            iconColor: Settings.colors.foreground.contrast
                            verticalOffset: 0
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ChevronButton {
                    id: closeBtn
                    enabled: !!mprisPlayer.player?.canQuit
                    opacity: enabled ? 1 : Settings.colors.foreground.dimOpacity
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Configuration.mprisHMargin
                    Layout.rightMargin: Configuration.mprisHMargin
                    contentLeftPadding: Configuration.mprisActionBtnPaddingS
                    contentRightPadding: Configuration.mprisActionBtnPaddingL

                    leftCap: Core.ChevronGeometry.Cap.Point
                    rightCap: Core.ChevronGeometry.Cap.Flat

                    bgFill: Settings.colors.background.tint2

                    onLeftClicked: Core.Media.quit()

                    Glyph {
                        icon: Configuration.mprisActionBtn.close
                        iconSize: Configuration.mprisPrevNextBtnSz
                        iconColor: enabled && closeBtn.hovered ? Settings.colors.foreground.accent : Settings.colors.foreground.main
                        verticalOffset: 0
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                id: mprisInfo
                Layout.fillWidth: true
                Layout.leftMargin: Configuration.mprisHMargin
                Layout.rightMargin: Configuration.mprisHMargin
                spacing: Configuration.mprisInfoVSpacing
                readonly property real marginCompensation: mprisPlayer.metadataMarginCompensation()
                Layout.topMargin: mprisSecondary.visible ? 0 : marginCompensation
                Layout.bottomMargin: mprisSecondary.visible ? 0 : marginCompensation

                Text {
                    id: mprisTrack
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: mprisPlayer.player ? mprisPlayer.player.trackTitle || "Unknown title" : "No active player"
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.mprisMetadataFontSz
                    font.weight: Font.Bold
                    color: Settings.colors.foreground.main
                }

                Item {
                    id: mprisSecondary
                    Layout.fillWidth: true
                    implicitHeight: Math.max(mprisArtist.implicitHeight, mprisAlbum.implicitHeight)
                    visible: mprisArtist.text.length || mprisAlbum.text.length
                    readonly property real separatorExtent: mprisPlayer.metadataSeparatorExtent()

                    // Center the bounded content, rather than stretching two
                    // text boxes whose preferred widths vary with each track.
                    Row {
                        id: secondaryContent
                        anchors.centerIn: parent
                        anchors.alignWhenCentered: false
                        spacing: Configuration.mprisInfoHSpacing

                        Text {
                            id: mprisArtist
                            width: mprisPlayer.artistWidth()
                            visible: text.length > 0
                            text: mprisPlayer.player?.trackArtist ?? ""
                            elide: Text.ElideRight
                            font.family: Settings.labelFontFamily
                            font.pixelSize: Configuration.mprisMetadataFontSz
                            color: Settings.colors.foreground.accent
                        }

                        Circle {
                            id: metadataSeparator
                            visible: mprisArtist.text.length > 0 && mprisAlbum.text.length > 0
                            anchors.verticalCenter: parent.verticalCenter
                            diameter: Settings.separatorDotSize
                            color: Settings.colors.foreground.muted
                        }

                        Text {
                            id: mprisAlbum
                            width: mprisPlayer.albumWidth()
                            visible: text.length > 0
                            text: mprisPlayer.player?.trackAlbum ?? ""
                            elide: Text.ElideRight
                            font.family: Settings.labelFontFamily
                            font.pixelSize: Configuration.mprisMetadataFontSz
                            color: Settings.colors.foreground.main
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                id: mprisBtns
                Layout.alignment: Qt.AlignHCenter
                spacing: Configuration.mprisPlayPausePadding - Core.ChevronGeometry.calcCapWidth(mprisPlayPause.height)

                ChevronButton {
                    id: mprisPrev
                    enabled: !!mprisPlayer.player?.canControl && mprisPlayer.player.canGoPrevious
                    opacity: enabled ? 1 : Settings.colors.foreground.dimOpacity
                    contentLeftPadding: Configuration.mprisButtonsPadding
                    contentRightPadding: Configuration.mprisButtonsPadding

                    leftCap: Core.ChevronGeometry.Cap.Point
                    rightCap: Core.ChevronGeometry.Cap.Notch

                    bgFill: Settings.colors.background.tint3

                    onLeftClicked: Core.Media.previous()

                    Glyph {
                        icon: Configuration.mprisPlayerBtn.prev
                        iconSize: Configuration.mprisPrevNextBtnSz
                        iconColor: Settings.colors.foreground.main
                        verticalOffset: 0
                    }
                }

                ChevronButton {
                    id: mprisPlayPause
                    enabled: !!mprisPlayer.player?.canControl && mprisPlayer.player.canTogglePlaying
                    opacity: enabled ? 1 : Settings.colors.foreground.dimOpacity
                    contentLeftPadding: Configuration.mprisButtonsPadding
                    contentRightPadding: Configuration.mprisButtonsPadding

                    leftCap: Core.ChevronGeometry.Cap.Point
                    rightCap: Core.ChevronGeometry.Cap.Point

                    bgFill: Settings.colors.background.accent

                    onLeftClicked: Core.Media.togglePlaying()

                    Glyph {
                        icon: mprisPlayer.playPauseIcon()
                        iconSize: Configuration.mprisPlayPauseBtnSz
                        iconColor: Settings.colors.foreground.contrast
                        verticalOffset: 0
                    }
                }

                ChevronButton {
                    id: mprisNext
                    enabled: !!mprisPlayer.player?.canControl && mprisPlayer.player.canGoNext
                    opacity: enabled ? 1 : Settings.colors.foreground.dimOpacity
                    contentLeftPadding: Configuration.mprisButtonsPadding
                    contentRightPadding: Configuration.mprisButtonsPadding

                    leftCap: Core.ChevronGeometry.Cap.Notch
                    rightCap: Core.ChevronGeometry.Cap.Point

                    bgFill: Settings.colors.background.tint3

                    onLeftClicked: Core.Media.next()

                    Glyph {
                        icon: Configuration.mprisPlayerBtn.next
                        iconSize: Configuration.mprisPrevNextBtnSz
                        iconColor: Settings.colors.foreground.main
                        verticalOffset: 0
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                id: mprisSeekbar
                Layout.fillWidth: true
                Layout.topMargin: Configuration.mprisSeekbarPaddingY
                spacing: 2

                HexagonSlider {
                    id: seekSlider
                    property var dragPlayer: null
                    property int dragTrackId: 0
                    property real dragPosition: 0

                    Layout.fillWidth: true
                    Layout.leftMargin: Configuration.mprisSeekbarPaddingX
                    Layout.rightMargin: Configuration.mprisSeekbarPaddingX

                    from: 0
                    to: mprisPlayer.trackLength > 0 ? mprisPlayer.trackLength : 1
                    actionable: mprisPlayer.seekable
                    bgFill: Settings.colors.background.tint2

                    Binding {
                        target: seekSlider
                        property: "value"
                        value: mprisPlayer.trackLength > 0 ? mprisPlayer.position : 0
                        when: !seekSlider.pressed
                        restoreMode: Binding.RestoreNone
                    }

                    onMoved: mprisPlayer.handleSeekMoved()
                    onPressedChanged: mprisPlayer.handleSeekPressedChanged()
                }

                RowLayout {
                    Text {
                        text: mprisPlayer.elapsedTimeText()
                        font.family: Settings.labelFontFamily
                        font.pixelSize: Configuration.mprisMetadataFontSz
                        color: Settings.colors.foreground.main
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mprisPlayer.durationText()
                        font.family: Settings.labelFontFamily
                        font.pixelSize: Configuration.mprisMetadataFontSz
                        color: Settings.colors.foreground.main
                    }
                }
            }
        }

        function readTrackLength(): real {
            return mprisPlayer.player?.lengthSupported ? Math.max(0, mprisPlayer.player.length) : 0
        }

        function readPosition(): real {
            if (!mprisPlayer.player?.positionSupported)
                return 0

            const position = mprisPlayer.player.position
            if (mprisPlayer.trackLength > 0)
                return Math.max(0, Math.min(position, mprisPlayer.trackLength))
            return Math.max(0, position)
        }

        function canSeek(): bool {
            return !!mprisPlayer.player?.canControl && mprisPlayer.player.canSeek
                && mprisPlayer.player.positionSupported && mprisPlayer.trackLength > 0
        }

        function positionRefreshInterval(): int {
            // Sample just after the next track-second boundary. A fixed interval
            // can repeatedly land before it, leaving the floored label a second late.
            const rate = mprisPlayer.player?.rate > 0 ? mprisPlayer.player.rate : 1
            const remaining = Math.floor(mprisPlayer.position) + 1 - mprisPlayer.position
            // Allow for QML Timer's animation-frame timing resolution.
            return Math.max(20, Math.ceil(remaining * 1000 / rate) + 20)
        }

        function refreshPosition(): void {
            if (mprisPlayer.player?.positionSupported)
                mprisPlayer.player.positionChanged()
        }

        function refreshVisiblePosition(): void {
            if (mprisPlayer.visible)
                mprisPlayer.refreshPosition()
        }

        function togglePlayerMenu(): void {
            if (playerMenu.visible && !playerMenu.closing)
                playerMenu.close()
            else
                playerMenu.open()
        }

        function metadataMarginCompensation(): real {
            return (mprisSecondary.implicitHeight + Configuration.mprisInfoVSpacing) / 2
        }

        function metadataSeparatorExtent(): real {
            return metadataSeparator.visible
                ? metadataSeparator.width + 2 * secondaryContent.spacing : 0
        }

        function artistWidth(): real {
            const ratio = Math.max(0, Math.min(1, Configuration.mprisArtistMaxWidthRatio))
            const available = Math.max(0, mprisSecondary.width - mprisSecondary.separatorExtent)
            return Math.min(mprisArtist.implicitWidth, mprisSecondary.width * ratio, available)
        }

        function albumWidth(): real {
            const artistWidth = mprisArtist.visible ? mprisArtist.width : 0
            const available = Math.max(0, mprisSecondary.width - artistWidth - mprisSecondary.separatorExtent)
            return Math.min(mprisAlbum.implicitWidth, available)
        }

        function playPauseIcon(): string {
            return mprisPlayer.player?.isPlaying ? Configuration.mprisPlayerBtn.pause : Configuration.mprisPlayerBtn.play
        }

        function handleSeekMoved(): void {
            if (seekSlider.pressed)
                seekSlider.dragPosition = seekSlider.value
            else
                Core.Media.seekTo(mprisPlayer.player, seekSlider.value)
        }

        function handleSeekPressedChanged(): void {
            if (seekSlider.pressed) {
                seekSlider.dragPlayer = mprisPlayer.player
                seekSlider.dragTrackId = mprisPlayer.player?.uniqueId ?? 0
                seekSlider.dragPosition = seekSlider.value
            } else {
                // A selection or track change during the drag cancels it.
                const player = seekSlider.dragPlayer
                if (player && player === mprisPlayer.player && player.uniqueId === seekSlider.dragTrackId)
                    Core.Media.seekTo(player, seekSlider.dragPosition)
                seekSlider.dragPlayer = null
            }
        }

        function elapsedTimeText(): string {
            if (!mprisPlayer.player?.positionSupported)
                return "--:--"
            return mprisPlayer.formatTime(seekSlider.pressed ? seekSlider.value : mprisPlayer.position)
        }

        function durationText(): string {
            return mprisPlayer.player?.lengthSupported ? mprisPlayer.formatTime(mprisPlayer.trackLength) : "--:--"
        }

        function formatTime(seconds: real): string {
            const total = Math.max(0, Math.floor(seconds))
            const minutes = Math.floor(total / 60)
            const remainder = String(total % 60).padStart(2, "0")
            if (minutes < 60)
                return minutes + ":" + remainder
            return Math.floor(minutes / 60) + ":" + String(minutes % 60).padStart(2, "0") + ":" + remainder
        }
    }
}
