import QtQuick
import Quickshell
import Quickshell.Wayland

import qs
import qs.core as Core

PanelWindow {
    id: root
    WlrLayershell.namespace: Settings.wlrLayerShellNamespace

    // The shared host is a sibling window, supplied by shell.qml. DropDown
    // controllers find it through their QsWindow attached property.
    property var popoutHost: null

    anchors {
        top: true
        left: true
        right: true
    }

    // ────── Bar Dimensions ──────
    implicitHeight: Settings.barHeight

    color: Settings.colors.bgMain

    // The focus grab includes the bar so another module can switch popouts.
    // Watch bar taps passively, then close only if the clicked control did not
    // replace the active popout. Qt.callLater lets the control handle the same
    // release first, regardless of signal delivery order.
    TapHandler {
        parent: root.contentItem
        enabled: root.popoutHost !== null && root.popoutHost.current !== null
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        gesturePolicy: TapHandler.DragThreshold

        property var openAtPress: null
        property int serialAtPress: 0

        onPressedChanged: {
            if (pressed) {
                openAtPress = root.popoutHost.current
                serialAtPress = root.popoutHost.interactionSerial
            }
        }

        onTapped: {
            const previous = openAtPress
            const serial = serialAtPress
            Qt.callLater(() => {
                // A widget action on this press, or any later press, wins over
                // this delayed blank-bar dismissal.
                if (root.popoutHost && root.popoutHost.interactionSerial === serial
                        && root.popoutHost.current === previous)
                    root.popoutHost.dismiss(previous)
            })
        }
    }

    // ────── Caffeine Mode ──────
    // The Wayland protocol attaches an inhibitor to a surface,
    // so it is anchored to the bar: the one window that is always mapped
    IdleInhibitor {
        window: root
        enabled: Core.Caffeine.enabled
    }

    // ────── Content ──────
    Item {
        id: contentBox

        // The focus grab can return keyboard focus to the bar after the
        // popout maps. Handle close keys here as well as in PopoutHost.
        focus: root.popoutHost !== null && root.popoutHost.current !== null
        Keys.onPressed: event => {
            const dropdown = root.popoutHost ? root.popoutHost.current : null
            if (dropdown && dropdown.closeKeys.includes(event.key)) {
                root.popoutHost.dismiss(dropdown)
                event.accepted = true
            }
        }

        anchors.fill: parent
        anchors.topMargin: Settings.barPaddingTop
        anchors.bottomMargin: Settings.barPaddingBottom
        anchors.leftMargin: Settings.barPaddingLeft
        anchors.rightMargin: Settings.barPaddingRight

        CenterSection {
            id: centerSection

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }

        LeftSection {
            id: leftSection

            anchors.left: parent.left
            anchors.right: centerSection.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            anchors.rightMargin: Settings.moduleSpacing - Core.ChevronGeometry.calcCapWidth(height)
        }

        RightSection {
            id: rightSection

            anchors.left: centerSection.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            anchors.leftMargin: Settings.moduleSpacing - Core.ChevronGeometry.calcCapWidth(height)
        }
    }

    // DEBUG: central line guides
    Rectangle {
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     anchors.top: parent.top
    //     anchors.bottom: parent.bottom

    //     width: 1
    //     color: "cyan"
    // }

    // Rectangle {
    //     anchors.left: parent.left
    //     anchors.right: parent.right
    //     anchors.verticalCenter: parent.verticalCenter

    //     height: 1
    //     color: "cyan"
    }
}
