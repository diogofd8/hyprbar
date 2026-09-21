import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs

Item {
    id: root

    default property Component menuContent

    implicitHeight: 0
    implicitWidth: 0
    visible: false

    property Item anchorItem: root.parent
    property int edges: Edges.Bottom
    property int gravity: Edges.Bottom
    property real spacing: Settings.barPaddingBottom
    property color backgroundColor: "transparent"

    property var closeKeys: Settings.popupCloseKeys

    readonly property bool isOpen: priv.isRequested

    function open() { priv.isRequested = true }
    function close() { priv.isRequested = false }
    function toggle() { priv.isRequested = !priv.isRequested }

    QtObject {
        id: priv
        property bool isRequested: false
    }

    HyprlandFocusGrab {
        active: popup.backingWindowVisible
        windows: [popup]

        onCleared: root.close()
    }

    PopupWindow {
        id: popup

        visible: contentLoader.item !== null
            && popup.implicitWidth > 0
            && popup.implicitHeight > 0

        anchor {
            item: root.anchorItem
            edges: root.edges
            gravity: root.gravity

            margins.top: (root.edges & Edges.Top) ? -root.spacing : 0
            margins.bottom: (root.edges & Edges.Bottom) ? -root.spacing : 0
            margins.left: (root.edges & Edges.Left) ? -root.spacing : 0
            margins.right: (root.edges & Edges.Right) ? -root.spacing : 0

            adjustment: PopupAdjustment.Slide
        }

        implicitWidth: contentLoader.implicitWidth
        implicitHeight: contentLoader.implicitHeight

        color: root.backgroundColor

        Loader {
            id: contentLoader
            anchors.fill: parent

            active: priv.isRequested
            sourceComponent: root.menuContent
            focus: true

            Keys.onPressed: event => {
                if (root.closeKeys.includes(event.key)) {
                    root.close()
                    event.accepted = true
                }
            }
        }
    }
}
