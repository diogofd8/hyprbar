import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs

// One layer surface for all bar dropdowns. Its fixed buffer never follows row
// animations; the mask makes the unused transparent area click-through.
PanelWindow {
    id: root

    required property var bar
    property var current: null
    property int interactionSerial: 0
    property int displayedSlot: -1
    property bool mapped: false
    property bool waitingToReveal: false
    property bool morphing: false
    property real morphProgress: 1
    property real fromX: 0
    property real fromWidth: 0
    property real fromHeight: 0
    property real reveal: 0
    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 0
    property real targetHeight: 0

    screen: root.bar.screen
    anchors { top: true; left: true; right: true }
    // Keep the bar's input surface uncovered instead of relying on this
    // window's transparent input mask to pass bar clicks through.
    margins.top: root.bar.height
    implicitHeight: Math.max(0, Math.min(Settings.popoutHostHeight,
        root.screen.height) - root.bar.height)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: Settings.wlrLayerShellNamespace + "-popout"
    WlrLayershell.layer: WlrLayer.Top
    // Ordinary popouts leave keyboard focus with the bar; the password field
    // explicitly requests it when it appears. Avoid taking focus on map,
    // which can swallow a rapid second click on another bar button.
    WlrLayershell.keyboardFocus: root.current && root.current.wantsKeyboardFocus
        && !root.current.holdOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"
    visible: root.mapped
    mask: Region { item: inputArea }

    Behavior on reveal {
        Anim {
            duration: root.current ? Motion.popoutOpenMs : Motion.popoutCloseMs
            easing.bezierCurve: root.current ? Motion.enterCurve : Motion.exitCurve
        }
    }

    function slot(index) { return index === 0 ? first : second }

    function retains(dropdown) {
        return first.owner === dropdown || second.owner === dropdown
    }

    function show(dropdown) {
        if (!dropdown || !dropdown.menuContent || root.current === dropdown)
            return

        ++root.interactionSerial
        root.current = dropdown

        if (root.displayedSlot >= 0 && root.slot(root.displayedSlot).owner === dropdown) {
            root.slot(1 - root.displayedSlot).owner = null
            root.reveal = 1
            root.updateTarget()
            return
        }

        const next = root.displayedSlot === 0 ? second : first
        if (next.owner === dropdown && next.status === Loader.Ready)
            root.ready(next)
        else
            next.owner = dropdown
    }

    function dismiss(dropdown) {
        if (!root.current || (dropdown && root.current !== dropdown))
            return

        ++root.interactionSerial
        root.current = null
        root.waitingToReveal = false
        root.reveal = 0
        if (root.displayedSlot < 0 || root.reveal <= 0)
            root.finishClose()
    }

    function ready(loader) {
        if (loader.owner !== root.current || loader.status !== Loader.Ready)
            return

        // A second widget can become ready before the first visible frame.
        // It still needs the initial reveal, with no geometry morph.
        const firstOpen = !root.mapped || root.waitingToReveal
        if (firstOpen) {
            morph.stop()
            root.morphing = false
            root.morphProgress = 1
        } else {
            // Snapshot the currently painted geometry. One progress animation
            // then moves all three dimensions, even if the target updates.
            const x = panel.x
            const width = panel.width
            const height = panel.height
            morph.stop()
            root.fromX = x
            root.fromWidth = width
            root.fromHeight = height
            root.morphProgress = 0
            root.morphing = true
        }

        root.displayedSlot = loader === first ? 0 : 1
        root.updateTarget()
        root.waitingToReveal = firstOpen
        root.mapped = true
        // A first open reveals from the window's first presented frame
        // (firstFrame below); a switch starts at once.
        if (!firstOpen) {
            root.reveal = 1
            morph.start()
        }
    }

    function updateTarget() {
        if (!root.current || root.displayedSlot < 0 || !root.bar)
            return

        const loader = root.slot(root.displayedSlot)
        if (loader.owner !== root.current || loader.status !== Loader.Ready
                || !root.current.anchorItem)
            return

        const rect = root.bar.itemRect(root.current.anchorItem)
        const width = Math.min(loader.implicitWidth, root.width)
        const height = Math.min(loader.implicitHeight, root.height)
        root.targetWidth = width
        root.targetHeight = height
        root.targetX = Math.max(0, Math.min(root.width - width,
            rect.x + rect.width / 2 - width / 2))
        root.targetY = Math.max(0, Math.min(root.height - height,
            rect.y + rect.height + root.current.spacing - root.bar.height))
    }

    function releaseUnused() {
        if (root.displayedSlot !== 0 && first.opacity === 0 && first.owner !== root.current)
            first.owner = null
        if (root.displayedSlot !== 1 && second.opacity === 0 && second.owner !== root.current)
            second.owner = null
    }

    function finishClose() {
        if (root.current || root.reveal > 0)
            return

        root.waitingToReveal = false
        root.mapped = false
        morph.stop()
        root.morphing = false
        root.displayedSlot = -1
        first.owner = null
        second.owner = null
    }

    onRevealChanged: if (root.reveal <= 0 && !root.current) root.finishClose()
    onWidthChanged: root.updateTarget()
    onHeightChanged: root.updateTarget()

    TransformWatcher {
        a: root.bar.contentItem
        b: root.current ? root.current.anchorItem : null
        onTransformChanged: root.updateTarget()
    }

    // Quickshell destroys a layer window when it's hidden, so every open builds
    // a new QQuickWindow, and its first frame is the slow one. Start the reveal
    // once that frame has been presented, so the animation never runs during it.
    // frameSwapped comes from the render thread; QML delivers it on this thread.
    Connections {
        id: firstFrame
        target: panel.Window.window
        enabled: root.waitingToReveal
        function onFrameSwapped() {
            root.waitingToReveal = false
            if (root.current)
                root.reveal = 1
        }
    }

    Anim {
        id: morph
        target: root
        property: "morphProgress"
        from: 0
        to: 1
        duration: Motion.popoutMorphMs
        easing.bezierCurve: Motion.standardCurve
        onFinished: {
            root.morphing = false
            root.releaseUnused()
        }
    }

    HyprlandFocusGrab {
        active: root.current !== null && !root.current.holdOpen
        windows: [root, root.bar]
        onCleared: if (root.current && !root.current.holdOpen) root.dismiss(root.current)
    }

    // Keep loading, focus, and cleanup identical for both crossfade slots.
    component ContentSlot: Loader {
        id: slotLoader

        required property int slotIndex
        required property var host
        property var owner: null

        // Natural size, centred in the panel. A morph moves the shared
        // background and the clip; it never re-lays out the widget itself.
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: implicitWidth
        height: implicitHeight
        active: owner !== null
        asynchronous: true
        sourceComponent: owner ? owner.menuContent : null
        focus: host.displayedSlot === slotIndex
        enabled: host.current === owner && host.displayedSlot === slotIndex
        opacity: host.displayedSlot === slotIndex ? 1 : 0
        onOpacityChanged: if (opacity === 0) host.releaseUnused()
        onStatusChanged: if (status === Loader.Ready) host.ready(slotLoader)
        onImplicitWidthChanged: if (host.displayedSlot === slotIndex) host.updateTarget()
        onImplicitHeightChanged: if (host.displayedSlot === slotIndex) host.updateTarget()

        Behavior on opacity {
            enabled: slotLoader.host.morphing
            NumberAnimation { duration: Motion.popoutCrossfadeMs }
        }
    }

    // Stop intercepting clicks as soon as closing starts, even while the
    // outgoing panel is still visible for its short exit animation.
    Item {
        id: inputArea
        x: panel.x
        y: panel.y
        width: root.current ? panel.width : 0
        height: root.current ? revealClip.height : 0
    }

    Item {
        id: panel
        x: root.morphing
            ? root.fromX + (root.targetX - root.fromX) * root.morphProgress
            : root.targetX
        y: root.targetY - Motion.popoutOffset * (1 - root.reveal)
        width: root.morphing
            ? root.fromWidth + (root.targetWidth - root.fromWidth) * root.morphProgress
            : root.targetWidth
        height: root.morphing
            ? root.fromHeight + (root.targetHeight - root.fromHeight) * root.morphProgress
            : root.targetHeight
        focus: root.current !== null

        Keys.onPressed: event => {
            if (root.current && root.current.closeKeys.includes(event.key)) {
                root.dismiss(root.current)
                event.accepted = true
            }
        }

        // Open and close reveal the panel vertically. The full content stays
        // laid out, so the clip does not change any widget's own geometry.
        Item {
            id: revealClip
            width: parent.width
            height: parent.height * root.reveal
            clip: true

            // One background for every widget. It follows the panel geometry,
            // so a switch morphs a single surface instead of crossfading two
            // translucent ones.
            Rectangle {
                width: parent.width
                height: panel.height
                color: Qt.alpha(Settings.colors.bgMain, Settings.colors.bgOpacity)

                border.width: 1
                border.color: Qt.alpha(Settings.colors.fgMain, Settings.colors.hoverOpacity)

                // Hide the top border so the panel joins the bar
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: parent.border.width
                    color: Settings.colors.bgMain
                }
            }

            ContentSlot {
                id: first
                slotIndex: 0
                host: root
            }

            ContentSlot {
                id: second
                slotIndex: 1
                host: root
            }
        }
    }
}
