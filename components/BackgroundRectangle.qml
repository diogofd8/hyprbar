import QtQuick

// Rectangle styling and geometry remain local; only its paint is projected.
Item {
    id: root

    property Item backgroundTarget: null
    property alias color: rectangle.color
    property alias border: rectangle.border
    property alias radius: rectangle.radius
    antialiasing: root.radius > 0

    readonly property BackgroundScope backgroundScope: BackgroundScope {
        sourceItem: root

        Rectangle {
            id: rectangle
            z: -1
            anchors.fill: parent
            antialiasing: root.antialiasing
        }
    }
}
