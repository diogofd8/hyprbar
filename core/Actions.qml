pragma Singleton

import Quickshell
import Quickshell.Hyprland

import qs

Singleton {
    id: root

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
        run(["rofi", "-show", "drun"]);
    }

    function powerMenu(): void {
        run([Quickshell.shellPath("scripts/powermenu.sh")]);
    }

    function terminal(title: string, command: string): void {
        run(["alacritty", "--title", title, "-e", "sh", "-c", command]);
    }

    function clipse(): void {
        run(["alacritty", "--class", "clipse", "-e", "clipse"]);
    }

    function sysUpdateCheck(): void {
        SystemUpdate.check();
    }

    function sysUpdate(): void {
        SystemUpdate.update();
    }

    function notificationMenu(): void {
        run(["swaync-client", "-t"]);
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

    function weatherPopUp(): void {
        run([Quickshell.shellPath("scripts/float_term.sh"),
            "waybar-weather", "curl", "-s", "wttr.in", "--keep-alive"
        ]);
    }

    function calendarPopUp(): void {
        run([Quickshell.shellPath("scripts/float_term.sh"),
            "waybar-calendar", "cal", "--keep-alive"
        ]);
    }

    function calendarFullPopUp(): void {
        run([Quickshell.shellPath("scripts/float_term.sh"),
            "waybar-calendar-full", "cal", "-Y", "--columns", "4", "--keep-alive"
        ]);
    }
}
