import QtQuick
import QtQuick.Layouts

// Keep the contents laid out while the visible height opens or closes.
Item {
    id: root

    property bool shown: false
    property alias spacing: row.spacing
    default property alias content: row.data

    implicitWidth: row.implicitWidth
    implicitHeight: root.shown ? row.implicitHeight : 0
    visible: root.shown || root.implicitHeight > 0
    enabled: root.shown
    clip: true

    Behavior on implicitHeight { Anim {} }

    RowLayout {
        id: row
        width: parent.width
        height: implicitHeight
    }
}
