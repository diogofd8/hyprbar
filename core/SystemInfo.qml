pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string hostname: hostnameFile.text().trim()
    readonly property string osId: root.readOsId(osReleaseFile.text())
    readonly property string desktop: Quickshell.env("XDG_CURRENT_DESKTOP") ?? ""
    readonly property string userName: Quickshell.env("USER") ?? Quickshell.env("LOGNAME") ?? ""
    property string userIconPath: ""
    readonly property url userIcon: root.iconUrl(root.userIconPath)

    readonly property real uptimeSeconds: root.readUptime(uptimeFile.text())
    readonly property int uptimeDays: Math.floor(root.uptimeSeconds / 86400)
    readonly property int uptimeHours: Math.floor(root.uptimeSeconds / 3600) % 24
    readonly property int uptimeMinutes: Math.floor(root.uptimeSeconds / 60) % 60

    FileView {
        id: hostnameFile
        path: "/proc/sys/kernel/hostname"
    }

    FileView {
        id: osReleaseFile
        path: "/etc/os-release"
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
    }

    // AccountsService's configuration is private. Resolve the user's object
    // and read its IconFile property over D-Bus, without a resident helper.
    Process {
        id: accountLookup
        command: ["busctl", "--system", "--json=short", "call",
            "org.freedesktop.Accounts", "/org/freedesktop/Accounts",
            "org.freedesktop.Accounts", "FindUserByName", "s", root.userName]
        stdout: StdioCollector { id: accountLookupOutput }

        onExited: code => {
            const path = code === 0 ? root.readBusString(accountLookupOutput.text) : ""
            if (!path) {
                root.userIconPath = ""
                return
            }
            accountIconReader.userPath = path
            accountIconReader.running = true
        }
    }

    Process {
        id: accountIconReader
        property string userPath: ""
        command: ["busctl", "--system", "--json=short", "get-property",
            "org.freedesktop.Accounts", userPath, "org.freedesktop.Accounts.User", "IconFile"]
        stdout: StdioCollector { id: accountIconOutput }

        onExited: code => {
            root.userIconPath = code === 0 ? root.readBusString(accountIconOutput.text) : ""
        }
    }

    function refresh(): void {
        hostnameFile.reload()
        osReleaseFile.reload()
        root.refreshUptime()
        if (root.userName && !accountLookup.running && !accountIconReader.running)
            accountLookup.running = true
    }

    function refreshUptime(): void {
        uptimeFile.reload()
    }

    function readOsId(contents: string): string {
        const match = /^ID=(.*)$/m.exec(contents)
        if (!match)
            return ""
        return match[1].trim().replace(/^(["'])(.*)\1$/, "$2")
    }

    function readUptime(contents: string): real {
        const seconds = parseFloat(contents)
        return Number.isFinite(seconds) ? Math.max(0, seconds) : 0
    }

    function readBusString(contents: string): string {
        try {
            const data = JSON.parse(contents).data
            const value = Array.isArray(data) ? data[0] : data
            return typeof value === "string" ? value : ""
        } catch (error) {
            return ""
        }
    }

    function iconUrl(path: string): url {
        if (!path.startsWith("/"))
            return ""
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }
}
