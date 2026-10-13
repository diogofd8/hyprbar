//@ pragma UseQApplication
//@ pragma Env QT_QPA_PLATFORMTHEME =

import Quickshell
import Quickshell.Io
import QtQuick

import qs.bar
import qs.components
import qs.core as Core
import qs.popups as Popups

ShellRoot {
    id: shell

    Core.NotificationService {}
    Popups.NotificationToasts {
        screen: bar.screen
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void {
            Core.Notifications.requestOpen()
        }
    }

    Bar {
        id: bar
        popoutHost: popoutHost
    }

    PopoutHost {
        id: popoutHost
        bar: bar
    }
}
