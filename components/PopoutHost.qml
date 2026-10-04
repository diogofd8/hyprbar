import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs

// One layer surface for all bar dropdowns. Its fixed buffer never follows row
// animations; the mask makes the unused transparent area click-through.
// Each dropdown gets its own content slot, created the first time it's shown.
PanelWindow {
    id: root

    required property PanelWindow bar
    property DropDown current: null
    property int interactionSerial: 0
    // The content slot on screen (it stays there while the panel closes)
    property Loader displayedSlot: null
    // One ContentSlot per dropdown shown so far (see slotFor)
    property var slots: []
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
    // The last popout whose content didn't fit, so the warning prints once
    property DropDown clampWarned: null

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

    // True while the dropdown's content is loaded, from show() until it has
    // faded out. Bindings re-run when `slots` is reassigned or a slot's
    // `active` changes.
    function retains(dropdown) {
        const slot = root.slots.find(s => s.owner === dropdown)
        return slot !== undefined && slot.active
    }

    function slotFor(dropdown) {
        let slot = root.slots.find(s => s.owner === dropdown)
        if (!slot) {
            slot = contentSlot.createObject(revealClip, { host: root, owner: dropdown })
            // Reassign (not push) so retains() bindings notice. Slots whose
            // dropdown was destroyed are destroyed too (destroy() is falsy).
            root.slots = root.slots.filter(s => s.owner !== null || s.destroy()).concat([slot])
        }
        return slot
    }

    function show(dropdown) {
        if (!dropdown || !dropdown.menuContent || root.current === dropdown)
            return

        ++root.interactionSerial
        root.current = dropdown

        // Reopened during its own close: reverse the reveal
        const slot = root.slotFor(dropdown)
        if (root.displayedSlot === slot) {
            root.reveal = 1
            root.updateTarget()
            return
        }

        // Still loaded (fading out after a switch): switch back at once.
        // Otherwise it's loading now that it's current, and calls ready().
        if (slot.status === Loader.Ready)
            root.ready(slot)
    }

    function dismiss(dropdown) {
        if (!root.current || (dropdown && root.current !== dropdown))
            return

        ++root.interactionSerial
        root.current = null
        root.waitingToReveal = false
        root.reveal = 0
        if (!root.displayedSlot || root.reveal <= 0)
            root.finishClose()
    }

    // ────── Bar input ──────
    // The bar is part of the focus grab (so another module can switch the
    // popout), which means a click on it doesn't clear the grab. Instead, any
    // bar tap that didn't change the popout closes it: blank bar, a workspace
    // pip, a launcher button. Bar.qml forwards its taps and keys here.
    property var barPressSnapshot: null

    function barPressed() {
        root.barPressSnapshot = { current: root.current, serial: root.interactionSerial }
    }

    function barTapped() {
        const snapshot = root.barPressSnapshot
        // Qt.callLater lets the control under the cursor handle the same
        // release first, whichever order the two receive it in. Any popout
        // change since the press (that control, or a later press) wins.
        Qt.callLater(() => {
            if (snapshot && root.interactionSerial === snapshot.serial
                    && root.current === snapshot.current)
                root.dismiss(snapshot.current)
        })
    }

    function handleKey(event) {
        if (root.current && root.current.closeKeys.includes(event.key)) {
            root.dismiss(root.current)
            event.accepted = true
        }
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

        root.displayedSlot = loader
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
        const loader = root.displayedSlot
        if (!root.current || !loader || !root.bar)
            return

        if (loader.owner !== root.current || loader.status !== Loader.Ready
                || !root.current.anchorItem)
            return

        const rect = root.bar.itemRect(root.current.anchorItem)
        const width = Math.min(loader.implicitWidth, root.width)
        const height = Math.min(loader.implicitHeight, root.height)
        // Compared with the height the host asks for: until Hyprland
        // configures a new window, width and height are placeholders.
        if (loader.implicitHeight > root.implicitHeight && root.clampWarned !== root.current) {
            root.clampWarned = root.current
            console.warn(`PopoutHost: popout content is ${loader.implicitHeight} px tall,`
                + ` taller than the host's ${root.implicitHeight} px; it is cut off.`
                + " Raise Settings.popoutHostHeight.")
        }
        root.targetWidth = width
        root.targetHeight = height
        root.targetX = Math.max(0, Math.min(root.width - width,
            rect.x + rect.width / 2 - width / 2))
        root.targetY = Math.max(0, Math.min(root.height - height,
            rect.y + rect.height + root.current.spacing - root.bar.height))
    }

    function finishClose() {
        if (root.current || root.reveal > 0)
            return

        root.waitingToReveal = false
        root.mapped = false
        morph.stop()
        root.morphing = false
        // With no slot on screen and no morph, every slot unloads at once
        root.displayedSlot = null
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
        onFinished: root.morphing = false
    }

    HyprlandFocusGrab {
        active: root.current !== null && !root.current.holdOpen
        windows: [root, root.bar]
        onCleared: if (root.current && !root.current.holdOpen) root.dismiss(root.current)
    }

    // A dropdown's content. It loads while its dropdown is current or it's on
    // screen, stays loaded until it has faded out, then unloads itself.
    component ContentSlot: Loader {
        id: slotLoader

        required property PopoutHost host
        required property DropDown owner
        readonly property bool shown: host.displayedSlot === slotLoader

        // Natural size, centred in the panel. A morph moves the shared
        // background and the clip; it never re-lays out the widget itself.
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: implicitWidth
        height: implicitHeight
        active: owner !== null && (host.current === owner || shown || opacity > 0)
        asynchronous: true
        sourceComponent: owner ? owner.menuContent : null
        focus: shown
        enabled: shown && host.current === owner
        opacity: shown ? 1 : 0
        onStatusChanged: if (status === Loader.Ready) host.ready(slotLoader)
        onImplicitWidthChanged: if (shown) host.updateTarget()
        onImplicitHeightChanged: if (shown) host.updateTarget()

        // Crossfade only during a switch; open and close use the reveal
        Behavior on opacity {
            enabled: slotLoader.host.morphing
            NumberAnimation { duration: Motion.popoutCrossfadeMs }
        }
    }

    Component {
        id: contentSlot
        ContentSlot {}
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

        Keys.onPressed: event => root.handleKey(event)

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
        }
    }
}
