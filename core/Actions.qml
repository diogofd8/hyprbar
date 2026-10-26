pragma Singleton

import Quickshell
import Quickshell.Hyprland

import qs

Singleton {
    id: root

    signal powerMenuRequested()
    signal applicationLauncherRequested()

    function run(argv): void {
        Quickshell.execDetached(argv);
    }

    function toggleDarkMode(): void {
        switch (Settings.theme) {
            case "dark":
                Settings.setTheme("light");
                break;
            case "light":
            default:
                Settings.setTheme("dark");
                break;
        }
    }

    function notify(summary: string, body: string, icon: string): void {
        const argv = ["notify-send", "-a", "quickshell"];
        if (icon)
            argv.push("-i", icon);
        argv.push(summary, body ?? "");
        run(argv);
    }

    function focusWorkspace(target: string): void {
        Hyprland.dispatch('hl.dsp.focus({ workspace = "' + target + '" })');
    }

    function launcher(): void {
        root.applicationLauncherRequested();
    }

    function powerMenu(): void {
        root.powerMenuRequested();
    }

    // Called only after the power menu's confirmation step.
    function performPowerAction(action: string): void {
        switch (action) {
        case "lock":
            run(["hyprlock"]);
            break;
        case "suspend":
            run(["systemctl", "suspend"]);
            break;
        case "reboot":
            run(["systemctl", "reboot"]);
            break;
        case "poweroff":
            run(["systemctl", "poweroff"]);
            break;
        case "logout":
            Hyprland.dispatch("hl.dsp.exit()");
            break;
        }
    }

    function terminal(title: string, command: string): void {
        run(["kitty", "--title", title, "-e", "sh", "-c", command]);
    }

    function clipse(): void {
        run(["kitty", "--class", "clipse", "-e", "clipse"]);
    }

    function sysUpdateCheck(): void {
        SystemUpdate.check();
    }

    function sysUpdate(): void {
        SystemUpdate.update();
    }

    function notificationMenu(): void {
        Notifications.requestOpen();
    }

    function networkManager(uuid): void {
        const argv = ["nm-connection-editor"];
        if (uuid)
            argv.push("--edit=" + uuid);
        run(argv);
    }

    function bluetoothManager(): void {
        run(["blueman-manager"]);
    }

    function vitalsPopUp(): void {
        run([Quickshell.shellPath("scripts/float_term.sh"), "waybar-vitals", "btop"]);
    }

}
