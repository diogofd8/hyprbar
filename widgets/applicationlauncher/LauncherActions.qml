pragma Singleton

import Quickshell

Singleton {
    id: root

    // Prefix used for desktop entries with Terminal=true.
    readonly property var terminalCommand: ["alacritty", "-e"]

    readonly property var actions: [
        {
            name: "Terminal",
            description: "Open a terminal",
            icon: "utilities-terminal",
            command: ["alacritty"]
        },
        {
            name: "Clipboard",
            description: "Open the clipboard manager",
            icon: "edit-paste",
            command: ["alacritty", "--class", "clipse", "-e", "clipse"]
        },
        {
            name: "System Monitor",
            description: "Open btop in a terminal",
            icon: "utilities-system-monitor",
            command: root.terminalCommand.concat(["btop"])
        }
    ]

    readonly property var applications: root.applicationEntries()

    function applicationEntries(): var {
        return DesktopEntries.applications.values
            .filter(application => !application.noDisplay)
            .map(application => ({
                name: application.name,
                description: application.comment || application.genericName,
                icon: application.icon,
                application: application
            }))
            .sort((left, right) => left.name.localeCompare(right.name))
    }

    function isCommandMode(input: string): bool {
        return input.trim().startsWith(">")
    }

    function matches(entry, terms): bool {
        const application = entry.application
        const searchable = [entry.name, entry.description,
            application?.genericName, application?.id,
            ...(application?.keywords ?? []), ...(entry.command ?? [])]
            .join(" ").toLocaleLowerCase()
        return terms.every(term => searchable.includes(term))
    }

    function search(input: string): var {
        const commandMode = root.isCommandMode(input)
        const query = (commandMode ? input.trim().slice(1) : input).trim()
        const terms = query.toLocaleLowerCase().split(/\s+/).filter(term => term.length > 0)
        const source = commandMode ? root.actions : root.applications
        const results = source.filter(entry => root.matches(entry, terms))

        if (commandMode && query.length > 0) {
            results.push({
                name: "Run: " + query,
                description: "Run this command in the shell",
                icon: "utilities-terminal",
                shellCommand: query
            })
        }
        return results
    }

    function execute(entry): void {
        if (entry.application) {
            const application = entry.application
            if (application.runInTerminal) {
                Quickshell.execDetached({
                    command: root.terminalCommand.concat(application.command),
                    workingDirectory: application.workingDirectory
                })
            } else {
                application.execute()
            }
        } else if (entry.shellCommand) {
            Quickshell.execDetached(root.terminalCommand.concat([
                "zsh", "-ic", `${entry.shellCommand}; exec zsh -i`
            ]))
        } else if (entry.command?.length > 0) {
            Quickshell.execDetached(entry.command)
        }
    }
}
