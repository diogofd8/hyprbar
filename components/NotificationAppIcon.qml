import QtQuick
import Quickshell
import Quickshell.Widgets

import qs
import qs.components

Item {
    id: root

    required property real iconSize
    property string source: ""
    property string desktopEntry: ""
    property string appName: ""

    // The application model may still be loading when the first notification arrives.
    readonly property var application: root.findApplication()
    readonly property string iconName: root.resolvedIconName()

    implicitWidth: root.iconSize
    implicitHeight: root.iconSize

    IconImage {
        id: appIcon

        anchors.fill: parent
        source: root.resolvedIconSource()
    }

    Glyph {
        anchors.centerIn: parent
        icon: Settings.notificationAppFallbackIcon
        useMetrics: false
        visible: appIcon.source.toString() === ""
    }

    // ────── Helper Functions ──────
    function findApplication(): var {
        if (DesktopEntries.applications.values.length === 0)
            return null

        return DesktopEntries.heuristicLookup(root.desktopEntry || root.appName)
    }

    function resolvedIconName(): string {
        return root.source || root.application?.icon || "application-x-executable"
    }

    function resolvedIconSource(): var {
        if (/^(\/|file:|image:)/.test(root.iconName))
            return root.iconName

        return Quickshell.iconPath(root.iconName, true)
    }
}
