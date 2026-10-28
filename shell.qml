//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import QtQuick

import qs.bar
import qs.components
import qs.core as Core
import qs.popups as Popups
import qs.widgets as Widgets

ShellRoot {
    id: shell

    function togglePowerMenu(): void {
        popoutHost.dismiss()
        hyprCheatSheet.active = false
        if (applicationLauncher.active)
            applicationLauncher.item.close()
        powerMenu.active = !powerMenu.active
    }

    function toggleApplicationLauncher(): void {
        popoutHost.dismiss()
        hyprCheatSheet.active = false
        powerMenu.active = false
        if (!applicationLauncher.active)
            applicationLauncher.active = true
        else if (applicationLauncher.item.closing)
            applicationLauncher.item.open()
        else
            applicationLauncher.item.close()
    }

    function toggleHyprCheatSheet(): void {
        popoutHost.dismiss()
        powerMenu.active = false
        if (applicationLauncher.active)
            applicationLauncher.item.close()
        hyprCheatSheet.active = !hyprCheatSheet.active
    }

    Connections {
        target: Core.Actions

        function onPowerMenuRequested(): void {
            shell.togglePowerMenu()
        }

        function onApplicationLauncherRequested(): void {
            shell.toggleApplicationLauncher()
        }

        function onHyprCheatSheetRequested(): void {
            shell.toggleHyprCheatSheet()
        }
    }

    LazyLoader {
        id: hyprCheatSheet

        Widgets.HyprCheatSheet {
            screen: bar.screen
            onDismissed: hyprCheatSheet.active = false
        }
    }

    IpcHandler {
        target: "hyprcheatsheet"
        function toggle(): void {
            shell.toggleHyprCheatSheet()
        }
    }

    LazyLoader {
        id: applicationLauncher

        Widgets.ApplicationLauncher {
            screen: bar.screen
            onDismissed: applicationLauncher.active = false
        }
    }

    IpcHandler {
        target: "applicationlauncher"
        function toggle(): void {
            shell.toggleApplicationLauncher()
        }
    }

    LazyLoader {
        id: powerMenu

        Widgets.PowerMenu {
            screen: bar.screen
            onDismissed: powerMenu.active = false
            onActionConfirmed: action => {
                powerMenu.active = false
                Core.Actions.performPowerAction(action)
            }
        }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void {
            shell.togglePowerMenu()
        }
    }

    function showSliderMenu(control: string): void {
        if (control !== "volume" && control !== "brightness")
            return
        sliderMenu.active = true
        sliderMenu.item.show(control)
    }

    LazyLoader {
        id: sliderMenu

        Widgets.SliderMenu {
            screen: bar.screen
            onDismissed: sliderMenu.active = false
        }
    }

    IpcHandler {
        target: "slidermenu"
        function open(control: string): void {
            shell.showSliderMenu(control)
        }
    }

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
