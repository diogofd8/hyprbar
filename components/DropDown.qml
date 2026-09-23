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
    property real spacing: Settings.dropDownPadding
    property color backgroundColor: "transparent"
    property int transitionDuration: Settings.dropDownTransitionMs
    property real transitionOffset: Settings.dropDownTransitionOffset

    property var closeKeys: Settings.popupCloseKeys

    readonly property bool isOpen: priv.isRequested
    property real transitionProgress: priv.isRequested ? 1 : 0

    Behavior on transitionProgress {
        SmoothedAnimation {
            duration: root.transitionDuration
            velocity: -1
            reversingMode: SmoothedAnimation.Eased
        }
    }

    function open() { priv.isRequested = true }
    function close() { priv.isRequested = false }
    function toggle() { priv.isRequested = !priv.isRequested }

    QtObject {
        id: priv
        property bool isRequested: false
    }

    HyprlandFocusGrab {
        active: priv.isRequested && popup.backingWindowVisible
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

            active: priv.isRequested || root.transitionProgress > 0
            sourceComponent: root.menuContent
            focus: priv.isRequested
            enabled: priv.isRequested
            opacity: root.transitionProgress

            transform: Translate {
                x: {
                    if (root.gravity & Edges.Right)
                        return -root.transitionOffset
                            * (1 - root.transitionProgress)
                    if (root.gravity & Edges.Left)
                        return root.transitionOffset
                            * (1 - root.transitionProgress)
                    return 0
                }
                y: {
                    if (root.gravity & Edges.Bottom)
                        return -root.transitionOffset
                            * (1 - root.transitionProgress)
                    if (root.gravity & Edges.Top)
                        return root.transitionOffset
                            * (1 - root.transitionProgress)
                    return 0
                }
            }

            Keys.onPressed: event => {
                if (root.closeKeys.includes(event.key)) {
                    root.close()
                    event.accepted = true
                }
            }
        }
    }
}
