import QtQuick
import Quickshell

import qs

// A bar-side controller. The shared PopoutHost owns the window and the loaded
// widget; modules keep their existing open/close and isOpen contract.
Item {
    id: root

    default property Component menuContent

    implicitHeight: 0
    implicitWidth: 0
    visible: false

    property Item anchorItem: root.parent
    property real spacing: Settings.dropDownPadding
    property var closeKeys: Settings.popupCloseKeys
    property bool holdOpen: false
    property bool wantsKeyboardFocus: false

    readonly property PopoutHost host: root.QsWindow.window
        ? (root.QsWindow.window.popoutHost || null) : null
    readonly property bool isOpen: root.host !== null && root.host.current === root
    readonly property bool contentActive: root.host !== null && root.host.retains(root)

    function open() {
        if (root.host)
            root.host.show(root)
    }

    function close() {
        if (root.host)
            root.host.dismiss(root)
    }

    function toggle() {
        if (root.isOpen)
            root.close()
        else
            root.open()
    }
}
