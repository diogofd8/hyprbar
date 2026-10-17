import QtQuick
import QtQuick.Controls.Basic as Controls

import qs
import qs.components
import qs.core as Core

Controls.Slider {
    id: root

    required property color parentBg
    required property string icon
    property bool available: true
    property bool selected: false
    readonly property bool interacting: root.pressed
    readonly property bool thumbHovered: root.isThumbHovered()
    readonly property bool valueVisible: root.pressed || root.thumbHovered || textTimer.running

    signal valueRequested(real value)

    orientation: Qt.Vertical
    from: 0
    to: 100
    stepSize: 1
    enabled: root.available
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    padding: 0
    topPadding: root.trackInsetY()
    bottomPadding: root.topPadding
    implicitWidth: Math.max(Configuration.sliderEntryTrackWidth, root.implicitHandleWidth)
    implicitHeight: Configuration.sliderEntryTrackHeight + root.implicitHandleHeight

    onMoved: root.valueRequested(value)
    onPressedChanged: root.revealValue()
    onThumbHoveredChanged: root.revealValue()

    Timer {
        id: textTimer
        interval: Configuration.sliderTextFadeTimerMs
        repeat: false
    }

    HoverHandler {
        id: pointer
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    // ────── Track ──────
    background: Item {
        id: track

        implicitWidth: Configuration.sliderEntryTrackWidth
        implicitHeight: Configuration.sliderEntryTrackHeight
        width: implicitWidth
        height: implicitHeight
        x: (root.width - width) / 2
        y: (root.height - height) / 2

        // Clip two copies of the same chevron so their angled edges match.
        Item {
            id: unfilledTrack

            width: parent.width
            height: parent.height * root.visualPosition
            clip: true

            Chevron {
                width: track.height
                height: track.width
                x: (parent.width - width) / 2
                y: root.trackChevronY(unfilledTrack)
                rotation: 90
                leftCap: Core.ChevronGeometry.Cap.Point
                rightCap: Core.ChevronGeometry.Cap.Point
                bgFill: Settings.colors.bgTint2
            }
        }

        Item {
            id: filledTrack

            y: unfilledTrack.height
            width: parent.width
            height: parent.height - y
            clip: true

            Chevron {
                width: track.height
                height: track.width
                x: (parent.width - width) / 2
                y: root.trackChevronY(filledTrack)
                rotation: 90
                leftCap: Core.ChevronGeometry.Cap.Point
                rightCap: Core.ChevronGeometry.Cap.Point
                bgFill: Settings.colors.accentMain
            }
        }
    }

    // ────── Thumb ──────
    handle: Controls.Pane {
        id: thumb

        // Let Slider own pointer input; this pane only paints and pads the thumb.
        enabled: false
        implicitHeight: root.regularThumbHeight()
        implicitWidth: implicitHeight * 2 / Math.sqrt(3)
        width: implicitWidth
        height: implicitHeight
        x: (root.width - width) / 2
        y: root.topPadding + root.visualPosition * (root.availableHeight - height)
        padding: 0

        background: Item {
            Hexagon {
                width: parent.width
                height: parent.height
                y: Configuration.sliderEntryThumbOffsetY
                fillColor: root.parentBg
            }

            Hexagon {
                id: thumbFace
                anchors.fill: parent
                fillColor: Settings.colors.accentMain
                hovered: root.selected || root.hovered || root.pressed
                hoverColor: Settings.colors.fgMain
                hoverOpacity: Settings.colors.hoverOpacity
            }
        }

        contentItem: Item {
            // Reserve the largest percentage so pressing never resizes the thumb.
            implicitWidth: Math.max(Configuration.sliderEntryIconSz, valueMetrics.advanceWidth)
            implicitHeight: Math.max(Configuration.sliderEntryIconSz, valueMetrics.tightBoundingRect.height)

            Glyph {
                x: (parent.width - width) / 2 + root.iconOffsetX()
                icon: root.valueVisible ? Math.round(root.value) : root.icon
                iconSize: root.valueVisible ? Configuration.sliderEntryFontSz : Configuration.sliderEntryIconSz
                iconColor: Settings.colors.fgDark
                font.family: root.valueVisible ? Settings.labelFontFamily : Settings.iconFontFamily
                font.bold: true
                useMetrics: false
            }

            TextMetrics {
                id: valueMetrics
                font.family: Settings.labelFontFamily
                font.pixelSize: Configuration.sliderEntryFontSz
                text: "100"
            }
        }
    }

    // ────── Helper Functions ──────
    function revealValue(): void {
        if (root.pressed || root.thumbHovered)
            textTimer.stop()
        else
            textTimer.restart()
    }

    function isThumbHovered(): bool {
        if (!pointer.hovered || thumb.width <= 0 || thumb.height <= 0)
            return false
        return thumbFace.containsPoint(pointer.point.position.x - thumb.x,
            pointer.point.position.y - thumb.y)
    }

    function iconOffsetX(): real {
        return root.valueVisible ? 0 : (Configuration.entryIconOffset[root.icon] ?? 0)
    }

    function regularThumbHeight(): real {
        const contentWidth = thumb.contentItem.implicitWidth + thumb.leftPadding + thumb.rightPadding
        const contentHeight = thumb.contentItem.implicitHeight + thumb.topPadding + thumb.bottomPadding
        // Fit the padded content rectangle inside all six sides.
        return Math.max(contentHeight, contentWidth * Math.sqrt(3) / 2 + contentHeight / 2)
    }

    function trackInsetY(): real {
        return Math.max(0, (root.height - track.height - thumb.height) / 2)
    }

    function trackChevronY(section: Item): real {
        return (track.height - track.width) / 2 - section.y
    }
}
