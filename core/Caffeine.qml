pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool enabled: false

    function toggle() {
        root.enabled = !root.enabled
    }
}
