import QtQuick
import Quickshell
import Quickshell.Wayland

import qs
import qs.core as Core

PanelWindow {
    id: root

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
