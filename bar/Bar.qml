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

    // While a popout is open, forwards taps on the bar to the host, which
    // decides whether they close it (PopoutHost.barTapped). Controls accept
    // their own presses first, so only taps on blank parts of the bar get here.
    TapHandler {
        parent: root.contentItem
        enabled: root.popoutHost !== null && root.popoutHost.current !== null
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        gesturePolicy: TapHandler.DragThreshold

        onPressedChanged: if (pressed) root.popoutHost.barPressed()
        onTapped: root.popoutHost.barTapped()
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

        // While a popout is open, close keys usually arrive here, not in the
        // popout (it takes keyboard focus only for the Wi-Fi password). The
        // host decides what they do.
        focus: root.popoutHost !== null && root.popoutHost.current !== null
        Keys.onPressed: event => root.popoutHost?.handleKey(event)

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
