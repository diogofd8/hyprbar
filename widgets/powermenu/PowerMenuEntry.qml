import QtQuick
import QtQuick.Layouts

import qs
import qs.components
import qs.core as Core

RowLayout {
    id: root

    required property string name
    required property string icon
    property color bgFill: Settings.colors.bgMain
    property bool confirmOpen: false
    property bool expanded: powerAction.hovered || root.activeFocus || root.confirmOpen

    signal clicked()
    signal confirmed()
    signal cancelled()

    // Declare the power action first while keeping Confirm to its left.
    layoutDirection: Qt.RightToLeft
    spacing: root.confirmActionsSpacing()
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: root.name
    Accessible.onPressAction: root.openConfirmation()

    Keys.onPressed: event => {
        if (!root.activeFocus)
            return
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Left) {
            if (!event.isAutoRepeat)
                root.openConfirmation()
            event.accepted = true
        } else if (event.key === Qt.Key_Right && root.confirmOpen) {
            root.cancelConfirmation(true)
            event.accepted = true
        }
    }

    Chevron {
        id: powerContainer

        Layout.alignment: Qt.AlignVCenter
        implicitHeight: Configuration.powerActionBtnHeight
        implicitWidth: root.powerWidth()
        leftCap: Core.ChevronGeometry.Cap.Point
        rightCap: Core.ChevronGeometry.Cap.Flat
        bgFill: root.bgFill

        Behavior on implicitWidth { Anim {} }

        ChevronButton {
            id: powerAction

            parent: powerContainer
            anchors.fill: parent
            anchors.margins: Configuration.powerActionBtnPadding
            leftCap: powerContainer.leftCap
            rightCap: powerContainer.rightCap
            bgFill: Settings.colors.bgTint2
            hoverOpacity: Settings.colors.hoverOpacityStrong
            onLeftClicked: root.clicked()

            RowLayout {
                // Bypass Chevron's default Row: this layout owns the content.
                parent: powerAction
                anchors.fill: parent
                anchors.leftMargin: root.actionLeftInset()
                anchors.rightMargin: Configuration.powerActionBtnRightPadding
                layoutDirection: Qt.RightToLeft
                spacing: Configuration.powerActionLabelPaddingX

                Glyph {
                    id: actionIcon

                    Layout.preferredWidth: Configuration.powerActionIconSz
                    Layout.alignment: Qt.AlignVCenter
                    icon: root.icon
                    iconSize: Configuration.powerActionIconSz
                    useMetrics: false
                    transform: Translate { y: root.inkOffset(actionIcon, iconMetrics) }

                    TextMetrics {
                        id: iconMetrics
                        font: actionIcon.font
                        text: actionIcon.text
                    }
                }

                Text {
                    id: actionLabel

                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    visible: powerContainer.width > collapsedWidth() + Configuration.powerActionLabelPaddingX
                    text: root.name
                    clip: true
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.powerActionLabelFontSz
                    transform: Translate { y: root.inkOffset(actionLabel, labelMetrics) }

                    TextMetrics {
                        id: labelMetrics
                        font: actionLabel.font
                        text: actionLabel.text
                    }
                }
            }
        }
    }

    Chevron {
        id: confirmContainer

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Core.ChevronGeometry.calcCapWidth(powerAction.height) + Configuration.confirmActionBtnWidth
        implicitHeight: Configuration.confirmActionBtnHeight
        visible: root.confirmOpen
        leftCap: Core.ChevronGeometry.Cap.Point
        rightCap: Core.ChevronGeometry.Cap.Notch
        bgFill: "transparent"

        ColumnLayout {
            parent: confirmContainer
            anchors.fill: parent
            spacing: Configuration.confirmActionsVSpacing
            uniformCellSizes: true

            Keys.onLeftPressed: event => event.accepted = true
            Keys.onRightPressed: root.cancelConfirmation(true)
            Keys.onEscapePressed: root.cancelConfirmation(true)

            ConfirmActionButton {
                id: noAction

                Layout.fillWidth: true
                Layout.fillHeight: true
                container: confirmContainer
                KeyNavigation.up: yesAction
                KeyNavigation.down: yesAction

                text: "No"
                glyph: Configuration.confirmActionIcon.no
                glyphColor: hovered || activeFocus ? Settings.colors.bgMain : Settings.colors.accentError
                bgFill: hovered || activeFocus ? Settings.colors.accentError : Settings.colors.bgMain

                onClicked: root.cancelConfirmation(noAction.visualFocus)
            }

            ConfirmActionButton {
                id: yesAction

                Layout.fillWidth: true
                Layout.fillHeight: true
                container: confirmContainer
                KeyNavigation.up: noAction
                KeyNavigation.down: noAction

                text: "Yes"
                glyph: Configuration.confirmActionIcon.yes
                glyphColor: hovered || activeFocus ? Settings.colors.bgMain : Settings.colors.accentCharging
                bgFill: hovered || activeFocus ? Settings.colors.accentCharging : Settings.colors.bgMain

                onClicked: root.confirmed()
            }
        }
    }

    // ────── Helper Functions ──────
    function openConfirmation(): void {
        if (!root.confirmOpen)
            root.clicked()
        noAction.forceActiveFocus(Qt.TabFocusReason)
    }

    function cancelConfirmation(restoreFocus: bool): void {
        root.cancelled()
        if (restoreFocus)
            root.forceActiveFocus(Qt.TabFocusReason)
    }

    function confirmActionsSpacing(): real {
        // Match the layouts' whole-pixel sizing so Confirm cannot move the right edge.
        return Math.round(Configuration.confirmActionsHMargin
            - Core.ChevronGeometry.calcCapWidth(powerContainer.height))
    }

    function collapsedWidth(): real {
        const buttonHeight = Configuration.powerActionBtnHeight - 2 * Configuration.powerActionBtnPadding
        return 2 * Configuration.powerActionBtnPadding + Core.ChevronGeometry.calcCapWidth(buttonHeight)
            + Configuration.powerActionBtnLeftPadding + Configuration.powerActionIconSz + Configuration.powerActionBtnRightPadding
    }

    function powerWidth(): real {
        return collapsedWidth() + (root.expanded ? actionLabel.implicitWidth + Configuration.powerActionLabelPaddingX : 0)
    }

    function actionLeftInset(): real {
        return Core.ChevronGeometry.calcCapWidth(powerAction.height) + Configuration.powerActionBtnLeftPadding
    }

    function inkOffset(textItem: Text, metrics: TextMetrics): real {
        // Centre the painted letters within their layout slot.
        const bounds = metrics.tightBoundingRect
        return textItem.height / 2 - textItem.baselineOffset - bounds.y - bounds.height / 2
    }
}
