import QtQuick

import qs
import qs.components
import qs.core as Core

Chevron {
    id: root
    contentLeftPadding: 2
    contentRightPadding: 2

    leftCap: Core.ChevronGeometry.Cap.Point
    rightCap: Core.ChevronGeometry.Cap.Point

    bgFill: Settings.colors.bgTint1

    Repeater {
        model: Core.WorkspaceModel.slots

        Item {
            id: pip

            required property var modelData
            readonly property int state: modelData.state
            readonly property bool active: state === Core.WorkspaceModel.State.Active

            height: root.height
            implicitWidth: icon.implicitWidth + Settings.workspaceSpacing

            Rectangle {
                anchors.fill: parent

                color: Settings.colors.fgMain
                opacity: Settings.workspaceHoverOpacity
                visible: mouse.containsMouse && !pip.active
            }

            Glyph {
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter

                text: {
                    switch (pip.state) {
                        case Core.WorkspaceModel.State.Active:
                            return Settings.activeWorkspaceIcon;
                        case Core.WorkspaceModel.State.Urgent:
                            return Settings.urgentWorkspaceIcon;
                        case Core.WorkspaceModel.State.Occupied:
                            return Settings.defaultWorkspaceIcon;
                        default:
                            return Settings.emptyWorkspaceIcon;
                    }
                }

                color: {
                    switch (pip.state) {
                        case Core.WorkspaceModel.State.Active:
                            return Settings.colors.accentMain;
                        case Core.WorkspaceModel.State.Urgent:
                            return Settings.colors.accentAlert;
                        default:
                            return Settings.colors.fgMain;
                    }
                }

                useMetrics: pip.active? true : false
                font.pixelSize: pip.active ? Settings.activeWorkspaceIconSize : Settings.workspaceIconSize
                verticalOffset: {
                    switch (pip.state) {
                        case Core.WorkspaceModel.State.Active:
                        case Core.WorkspaceModel.State.Urgent:
                            return -Settings.inducedVerticalOffset;
                        default:
                            return 0;
                    }
                }
            }

            MouseArea {
                id: mouse

                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: Core.WorkspaceModel.activate(pip.modelData)
            }
        }
    }
}
