pragma Singleton

import Quickshell

Singleton {
    function volumeManager(): void {
        Quickshell.execDetached(["pavucontrol"]);
    }
}
