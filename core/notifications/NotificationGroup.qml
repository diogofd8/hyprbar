import QtQuick
import Quickshell

Scope {
    required property string key
    property QtObject latest: null
    readonly property alias model: members
    readonly property int count: members.count

    ListModel { id: members }
}
