import QtQuick
import Quickshell
import Quickshell.Wayland

import qs
import qs.components
import qs.core as Core

PanelWindow {
    id: root
    WlrLayershell.namespace: Settings.wlrLayerShellNamespace

    // The shared host is a sibling window, supplied by shell.qml. DropDown
    // controllers find it through their QsWindow attached property.
    property PopoutHost popoutHost: null

    anchors {
        top: true
        left: true
        right: true
    }

    // ────── Bar Dimensions ──────
    implicitHeight: Settings.barHeight

    color: Settings.colors.bgMain

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

    // ────── Popout Dismissal ──────
    // Stacked above the content, so its handler is offered every press before
    // the controls are. A PointHandler only ever takes a passive grab, so the
    // controls still get their clicks (a TapHandler here blocked them). The
    // host closes the popout on any bar tap that didn't change it
    // (PopoutHost.barTapped).
    Item {
        anchors.fill: parent

        PointHandler {
            enabled: root.popoutHost !== null && root.popoutHost.current !== null
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onActiveChanged: {
                if (active)
                    root.popoutHost.barPressed()
                else
                    root.popoutHost.barTapped()
            }
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
