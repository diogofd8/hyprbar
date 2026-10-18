import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs
import qs.components
import qs.core as Core
import "applicationlauncher" as LauncherUI

// Keep the Wayland buffer stable while the panel reveals and its results resize.
PanelWindow {
    id: root

    readonly property Item backgroundTarget: panelBackground.paintTarget

    property alias searchText: inputField.text
    property bool focusGrabEnabled: true
    property bool closing: false
    property bool waitingToReveal: true
    property real reveal: 0
    property real clearReveal: inputField.text.length > 0 ? 1 : 0
    readonly property bool commandMode: LauncherUI.LauncherActions.isCommandMode(inputField.text)
    readonly property var results: LauncherUI.LauncherActions.search(inputField.text)
    readonly property real entryHeight: root.measureEntryHeight()

    signal dismissed()

    WlrLayershell.namespace: "hyprbar-applicationlauncher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.OnDemand
    anchors.bottom: true
    margins.bottom: LauncherUI.Configurations.appLauncherEdgeMargin
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: root.windowWidth()
    implicitHeight: root.windowHeight()
    mask: Region { item: inputMask }

    onResultsChanged: Qt.callLater(root.resetSelection)
    onRevealChanged: root.finishClose()

    Behavior on reveal {
        Anim {
            duration: root.closing ? Motion.popoutCloseMs : Motion.popoutOpenMs
            easing.bezierCurve: root.closing ? Motion.exitCurve : Motion.enterCurve
        }
    }

    Behavior on clearReveal { Anim {} }

    Connections {
        target: panel.Window.window
        enabled: root.waitingToReveal

        function onFrameSwapped(): void {
            root.revealPanel()
        }
    }

    HyprlandFocusGrab {
        active: root.focusGrabEnabled && !root.closing && !root.waitingToReveal
        windows: [root]
        onCleared: root.close()
    }

    FontMetrics {
        id: nameMetrics
        font.family: LauncherUI.Configurations.listEntryFont
        font.pixelSize: LauncherUI.Configurations.listEntryFontSz
    }

    FontMetrics {
        id: descriptionMetrics
        font.family: LauncherUI.Configurations.listEntryFont
        font.pixelSize: LauncherUI.Configurations.listEntryDescriptionFontSz
    }

    Item {
        id: inputMask
        x: panel.x
        y: panel.y
        width: root.closing ? 0 : panel.width
        height: panel.height
    }

    Controls.Pane {
        id: panel

        readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: panel }

        width: parent.width
        height: root.panelHeight()
        y: root.panelY()
        enabled: !root.closing
        focus: true
        opacity: root.reveal
        bottomPadding: LauncherUI.Configurations.appLauncherBottomPadding
        topPadding: LauncherUI.Configurations.appLauncherTopPadding
        verticalPadding: LauncherUI.Configurations.appLauncherPaddingY
        clip: true

        Behavior on height {
            enabled: !root.waitingToReveal && !root.closing
            Anim {
                duration: Motion.popoutMorphMs
                easing.bezierCurve: Motion.standardCurve
            }
        }

        background: BackgroundSurface {
            id: panelBackground
            readonly property real edgeWidth: 1 / root.devicePixelRatio
            readonly property color edgeColor: Settings.colors.background.border

            Rectangle {
                x: panelBackground.edgeWidth
                y: panelBackground.edgeWidth
                width: Math.max(0, parent.width - 2 * panelBackground.edgeWidth)
                height: Math.max(0, parent.height - panelBackground.edgeWidth)
                color: Settings.colors.background.main
            }

            Rectangle {
                width: parent.width
                height: panelBackground.edgeWidth
                color: panelBackground.edgeColor
            }

            Rectangle {
                y: panelBackground.edgeWidth
                width: panelBackground.edgeWidth
                height: Math.max(0, parent.height - panelBackground.edgeWidth)
                color: panelBackground.edgeColor
            }

            Rectangle {
                anchors.right: parent.right
                y: panelBackground.edgeWidth
                width: panelBackground.edgeWidth
                height: Math.max(0, parent.height - panelBackground.edgeWidth)
                color: panelBackground.edgeColor
            }
        }

        contentItem: ColumnLayout {
            id: launcherContainer
            spacing: LauncherUI.Configurations.launcherContainerVSpacing

            RowLayout {
                id: launcherContent
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                spacing: LauncherUI.Configurations.launcherContentHSpacing

                ColumnLayout {
                    id: applicationList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    spacing: LauncherUI.Configurations.applicationListVSpacing

                    ListView {
                        id: applicationView

                        readonly property BackgroundScope backgroundScope: BackgroundScope { sourceItem: applicationView }
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 0
                        visible: count > 0
                        clip: true
                        model: root.results
                        spacing: LauncherUI.Configurations.applicationListVSpacing
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentHeight > height
                        keyNavigationEnabled: false
                        Controls.ScrollBar.vertical: applicationScrollBar

                        WheelHandler {
                            parent: applicationView
                            target: null
                            enabled: applicationView.interactive
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => root.scrollApplications(event)
                        }

                        delegate: Controls.ItemDelegate {
                            id: entry
                            required property int index
                            required property var modelData

                            width: ListView.view.width
                            height: root.entryHeight
                            horizontalPadding: LauncherUI.Configurations.listEntryPaddingX
                            verticalPadding: LauncherUI.Configurations.listEntryPaddingY
                            focusPolicy: Qt.NoFocus
                            hoverEnabled: true
                            highlighted: applicationView.currentIndex === entry.index

                            onClicked: root.launchEntry(entry.index)

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }

                            background: BackgroundRectangle {
                                color: root.entryBackgroundColor(entry)
                            }

                            contentItem: RowLayout {
                                id: listEntry
                                spacing: LauncherUI.Configurations.listEntryHSpacing

                                IconImage {
                                    id: applicationIcon
                                    Layout.rightMargin: LauncherUI.Configurations.listEntryPaddingX
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitSize: LauncherUI.Configurations.listEntryIconSz
                                    source: root.iconSource(entry.modelData.icon)
                                }

                                ColumnLayout {
                                    id: listEntryMeta
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: LauncherUI.Configurations.listEntryMetaVSpacing

                                    Text {
                                        id: entryName
                                        Layout.fillWidth: true
                                        text: entry.modelData.name
                                        textFormat: Text.PlainText
                                        elide: Text.ElideRight
                                        font.family: LauncherUI.Configurations.listEntryFont
                                        font.pixelSize: LauncherUI.Configurations.listEntryFontSz
                                        color: Settings.colors.foreground.main
                                    }

                                    Text {
                                        id: entryDescription
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                        text: entry.modelData.description ?? ""
                                        textFormat: Text.PlainText
                                        elide: Text.ElideRight
                                        font.family: LauncherUI.Configurations.listEntryFont
                                        font.pixelSize: LauncherUI.Configurations.listEntryDescriptionFontSz
                                        color: Settings.colors.foreground.muted
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: applicationView.count === 0
                        text: "No applications found"
                        font.family: LauncherUI.Configurations.listEntryFont
                        font.pixelSize: LauncherUI.Configurations.listEntryFontSz
                        color: Settings.colors.foreground.muted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ColumnLayout {
                    id: scrollBarContainer
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    visible: applicationView.visible && applicationView.interactive
                    spacing: LauncherUI.Configurations.scrollBarVSpacing

                    Controls.AbstractButton {
                        id: scrollTopEnd
                        Layout.preferredWidth: LauncherUI.Configurations.scrollBarButtonWidth
                        Layout.fillWidth: false
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: LauncherUI.Configurations.scrollBarChevronHeight
                        Layout.fillHeight: false
                        enabled: !applicationView.atYBeginning
                        focusPolicy: Qt.NoFocus
                        padding: 0
                        opacity: enabled ? Settings.colors.background.dimOpacity : 1
                        onClicked: applicationScrollBar.decrease()

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        background: null
                        contentItem: LauncherUI.ScrollChevron {
                            pointUp: true
                            bgFill: Settings.colors.background.tint3
                        }
                    }

                    Controls.ScrollBar {
                        id: applicationScrollBar
                        parent: scrollBarContainer
                        Layout.preferredWidth: LauncherUI.Configurations.scrollBarWidth
                        Layout.fillWidth: false
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.minimumHeight: 0
                        policy: Controls.ScrollBar.AsNeeded
                        focusPolicy: Qt.NoFocus
                        padding: 0
                        minimumSize: root.minimumScrollThumbSize()
                        stepSize: root.scrollStepSize()

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        contentItem: LauncherUI.ScrollChevron {
                            leftCap: Core.ChevronGeometry.Cap.Point
                            opacity: applicationScrollBar.active
                                ? Settings.colors.background.hoverOpacity + Settings.colors.background.dimOpacity
                                : Settings.colors.background.dimOpacity
                        }

                        background: null
                    }

                    Controls.AbstractButton {
                        id: scrollBottomEnd
                        Layout.preferredWidth: LauncherUI.Configurations.scrollBarButtonWidth
                        Layout.fillWidth: false
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: LauncherUI.Configurations.scrollBarChevronHeight
                        Layout.fillHeight: false
                        enabled: !applicationView.atYEnd
                        focusPolicy: Qt.NoFocus
                        padding: 0
                        opacity: enabled ? Settings.colors.background.dimOpacity : 1
                        onClicked: applicationScrollBar.increase()

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        background: null
                        contentItem: LauncherUI.ScrollChevron {
                            bgFill: Settings.colors.background.tint3
                        }
                    }
                }
            }

            RowLayout {
                id: inputBar
                Layout.fillWidth: true
                Layout.fillHeight: false
                spacing: 0

                Chevron {
                    Layout.fillHeight: true
                    leftCap: Core.ChevronGeometry.Cap.Flat
                    rightCap: Core.ChevronGeometry.Cap.Point
                    bgFill: Settings.colors.background.tint1
                    contentLeftPadding: LauncherUI.Configurations.inputFieldIconMarginL
                    contentRightPadding: LauncherUI.Configurations.inputFieldIconMarginS

                    Glyph {
                        id: searchIcon
                        icon: root.inputIcon()
                        iconSize: LauncherUI.Configurations.inputBarIconSz
                        useMetrics: false
                        verticalOffset: 0
                    }
                }

                Controls.TextField {
                    id: inputField
                    Layout.fillWidth: true
                    Layout.leftMargin: root.inputJoinSpacing()
                    focus: true
                    padding: LauncherUI.Configurations.inputFieldPadding
                    leftPadding: root.inputLeftPadding()
                    rightPadding: root.inputRightPadding()
                    placeholderText: root.inputPlaceholder()
                    font.family: root.inputFont()
                    font.pixelSize: root.inputFontSz()
                    color: Settings.colors.foreground.main
                    placeholderTextColor: Settings.colors.foreground.muted
                    selectionColor: Settings.colors.foreground.accent
                    selectedTextColor: Settings.colors.foreground.contrast
                    selectByMouse: true

                    background: Chevron {
                        id: inputArea
                        implicitWidth: 0
                        implicitHeight: 0
                        leftCap: Core.ChevronGeometry.Cap.Notch
                        rightCap: Core.ChevronGeometry.Cap.Notch
                        rightCapProgress: root.clearReveal
                        bgFill: Settings.colors.background.tint1
                    }

                    onAccepted: root.launchCurrent()
                    Keys.onEscapePressed: root.close()
                    Keys.onUpPressed: root.moveSelection(-1)
                    Keys.onDownPressed: root.moveSelection(1)
                }

                ChevronButton {
                    id: clearBtn
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: root.clearButtonWidth()
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.leftMargin: root.inputJoinSpacing() * root.clearReveal
                    visible: root.clearReveal > 0
                    enabled: inputField.text.length > 0
                    opacity: root.clearReveal
                    clip: true
                    leftCap: Core.ChevronGeometry.Cap.Point
                    rightCap: Core.ChevronGeometry.Cap.Flat
                    leftCapProgress: root.clearReveal
                    bgFill: Settings.colors.background.tint1
                    contentLeftPadding: LauncherUI.Configurations.inputFieldIconMarginS
                    contentRightPadding: LauncherUI.Configurations.inputFieldIconMarginL

                    onLeftClicked: root.clearInput()

                    Glyph {
                        id: clearIcon
                        icon: LauncherUI.Configurations.inputBarIcons.clear
                        iconSize: LauncherUI.Configurations.inputBarIconSz
                        opacity: root.clearIconOpacity()
                        useMetrics: false
                        verticalOffset: 0
                    }
                }
            }
        }
    }

    // ────── Helper Functions ──────
    function windowWidth(): real {
        return Math.max(1, Math.min(LauncherUI.Configurations.appLauncherWidth,
            root.screen.width - 2 * LauncherUI.Configurations.appLauncherEdgeMargin))
    }

    function windowHeight(): real {
        return Math.max(1, root.screen.height - Settings.barHeight
            - 2 * LauncherUI.Configurations.appLauncherEdgeMargin)
    }

    function measureEntryHeight(): real {
        const metadataHeight = nameMetrics.height + descriptionMetrics.height
            + LauncherUI.Configurations.listEntryMetaVSpacing
        return Math.ceil(Math.max(LauncherUI.Configurations.listEntryIconSz, metadataHeight)
            + 2 * LauncherUI.Configurations.listEntryPaddingY)
    }

    function panelHeight(): real {
        const count = Math.max(1, Math.min(root.results.length,
            Math.max(1, LauncherUI.Configurations.listMaxEntries)))
        const listHeight = count * root.entryHeight
            + (count - 1) * LauncherUI.Configurations.applicationListVSpacing
        const padding = panel.topPadding + panel.bottomPadding
        return Math.min(root.height, listHeight + inputBar.implicitHeight
            + LauncherUI.Configurations.launcherContainerVSpacing + padding)
    }

    function panelY(): real {
        return panel.parent.height - panel.height * root.reveal
            + Motion.popoutOffset * (1 - root.reveal)
    }

    function minimumScrollThumbSize(): real {
        return Math.min(1, LauncherUI.Configurations.scrollBarThumbMinHeight
            / Math.max(1, applicationScrollBar.availableHeight))
    }

    function scrollStepSize(): real {
        return root.scrollStepDistance() / Math.max(1, applicationView.contentHeight)
    }

    function scrollStepDistance(): real {
        return (root.entryHeight + LauncherUI.Configurations.applicationListVSpacing)
            * Math.max(0, LauncherUI.Configurations.scrollSpeed)
    }

    function scrollApplications(event): void {
        if (event.pixelDelta.y === 0 && event.angleDelta.y === 0) {
            event.accepted = false
            return
        }
        const distance = event.pixelDelta.y !== 0
            ? event.pixelDelta.y * Math.max(0, LauncherUI.Configurations.scrollSpeed)
            : event.angleDelta.y / 120 * root.scrollStepDistance()
        const minimum = applicationView.originY
        const maximum = minimum + Math.max(0, applicationView.contentHeight - applicationView.height)
        applicationView.cancelFlick()
        applicationView.contentY = Math.max(minimum, Math.min(maximum, applicationView.contentY - distance))
        event.accepted = true
    }

    function entryBackgroundColor(entry): color {
        if (entry.highlighted)
            return Settings.colors.background.tint1
        if (entry.down || entry.hovered)
            return Settings.colors.background.tint1
        const alpha = entry.index % 2 === 0 ? LauncherUI.Configurations.listEntryOddAlpha : 1
        return Qt.tint(Settings.colors.background.tint1, Qt.alpha(Settings.colors.background.main, alpha))
    }

    function inputIcon(): string {
        return root.commandMode ? LauncherUI.Configurations.inputBarIcons.command
            : LauncherUI.Configurations.inputBarIcons.search
    }

    function inputFont(): string {
        return root.commandMode ? LauncherUI.Configurations.commandInputFont
            : LauncherUI.Configurations.listEntryFont
    }

    function inputFontSz(): real {
        return root.commandMode ? LauncherUI.Configurations.commandInputFontSz
            : LauncherUI.Configurations.listEntryFontSz
    }

    function inputPlaceholder(): string {
        return root.commandMode ? LauncherUI.Configurations.commandFieldPlaceholder
            : LauncherUI.Configurations.inputFieldPlaceholder
    }

    function inputJoinSpacing(): real {
        return LauncherUI.Configurations.inputBarHSpacing
            - Core.ChevronGeometry.calcCapWidth(inputField.height)
    }

    function inputLeftPadding(): real {
        return LauncherUI.Configurations.inputFieldPadding
            + Core.ChevronGeometry.calcCapWidth(inputField.height)
    }

    function inputRightPadding(): real {
        return LauncherUI.Configurations.inputFieldPadding
            + Core.ChevronGeometry.calcCapWidth(inputField.height) * root.clearReveal
    }

    function clearButtonWidth(): real {
        const contentWidth = clearIcon.width
            + clearBtn.contentLeftPadding + clearBtn.contentRightPadding
        const capWidth = Core.ChevronGeometry.calcCapWidth(inputField.height)
        return (contentWidth + capWidth) * root.clearReveal
    }

    function clearIconOpacity(): real {
        // Fade the whole icon in once the opening button can contain it.
        const contentWidth = clearIcon.width
            + clearBtn.contentLeftPadding + clearBtn.contentRightPadding
        const fitProgress = (clearIcon.width + clearBtn.contentLeftPadding) / contentWidth
        if (root.clearReveal >= 1)
            return 1
        if (root.clearReveal <= fitProgress)
            return 0
        return (root.clearReveal - fitProgress) / (1 - fitProgress)
    }

    function iconSource(icon: string): string {
        if (icon.startsWith("/"))
            return "file://" + icon
        if (/^(file:|image:)/.test(icon))
            return icon
        return Quickshell.iconPath(icon, true)
            || Quickshell.iconPath(LauncherUI.Configurations.applicationFallbackIcon, true)
    }

    function resetSelection(): void {
        applicationView.currentIndex = root.results.length > 0 ? 0 : -1
        applicationView.positionViewAtBeginning()
    }

    function moveSelection(step: int): void {
        const count = root.results.length
        if (count === 0)
            return
        applicationView.currentIndex = (applicationView.currentIndex + step + count) % count
        applicationView.positionViewAtIndex(applicationView.currentIndex, ListView.Contain)
    }

    function launchCurrent(): void {
        const entry = root.results[applicationView.currentIndex]
        if (!entry || root.closing)
            return
        LauncherUI.LauncherActions.execute(entry)
        root.close()
    }

    function launchEntry(index: int): void {
        applicationView.currentIndex = index
        root.launchCurrent()
    }

    function clearInput(): void {
        inputField.clear()
        inputField.forceActiveFocus()
    }

    function revealPanel(): void {
        root.waitingToReveal = false
        if (!root.closing)
            root.reveal = 1
    }

    function open(): void {
        root.closing = false
        root.waitingToReveal = true
    }

    function close(): void {
        if (root.closing)
            return
        root.closing = true
        root.reveal = 0
        root.finishClose()
    }

    function finishClose(): void {
        if (root.closing && root.reveal <= 0)
            root.dismissed()
    }
}
