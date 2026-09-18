import QtQuick

import qs
import qs.components
import qs.core as Core

Chevron {
    id: root
    contentLeftPadding: -Core.ChevronGeometry.calcCapWidth(height)
    contentRightPadding: 0

    leftCap: Core.ChevronGeometry.Cap.Flat
    rightCap: Core.ChevronGeometry.Cap.Notch

    bgFill: Settings.colors.bgTint2

    // Controls volume UI input/output switcher
    property bool showingInput: false

    // Core hands over a state; turning it into a colour is the view's job.
    function stateColor(node) {
        return node.state === "muted"
            ? Settings.colors.accentError
            : Settings.colors.fgMain
    }

    Row {
        // Input — the microphone.
        visible: root.showingInput

        ChevronButton {
            height: root.height
            contentLeftPadding: 2
            contentRightPadding: 2

            leftCap: Core.ChevronGeometry.Cap.Point
            rightCap: Core.ChevronGeometry.Cap.Point

            bgFill: Settings.colors.bgTint4
            hoverOpacity: 2 * Settings.colors.hoverOpacity

            onLeftClicked: Core.Audio.toggleSourceMute()
            onRightClicked: root.showingInput = !root.showingInput
            onScrolled: steps => Core.Audio.stepSourceVolume(steps)

            Glyph {
                icon: Core.Audio.source.icon
                color: root.stateColor(Core.Audio.source)
            }
        }

        Chevron {
            height: root.height
            contentLeftPadding: 3
            contentRightPadding: 3

            leftCap: Core.ChevronGeometry.Cap.Flat
            rightCap: Core.ChevronGeometry.Cap.Flat

            bgFill: Settings.colors.bgTint2

            Percentage {
                visible: !Core.Audio.source.muted

                height: root.height
                value: Core.Audio.source.value
            }

            Text {
                visible: Core.Audio.source.muted
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Settings.inducedVerticalOffset

                text: "MUTED"
                color: Settings.colors.accentError
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize
                font.weight: Font.Bold
            }
        }
    }

    Row {
        // Output — speakers or headphones, whichever Core.Audio reports.
        visible: !root.showingInput

        ChevronButton {
            height: root.height
            contentLeftPadding: 2
            contentRightPadding: 2

            leftCap: Core.ChevronGeometry.Cap.Point
            rightCap: Core.ChevronGeometry.Cap.Point

            bgFill: Settings.colors.bgTint4
            hoverOpacity: 2 * Settings.colors.hoverOpacity

            onLeftClicked: Core.Audio.toggleMute()
            onRightClicked: root.showingInput = !root.showingInput
            onScrolled: steps => Core.Audio.stepVolume(steps)

            Glyph {
                icon: Core.Audio.sink.icon
                color: root.stateColor(Core.Audio.sink)
            }
        }

        Chevron {
            height: root.height
            contentLeftPadding: 3
            contentRightPadding: 3

            leftCap: Core.ChevronGeometry.Cap.Flat
            rightCap: Core.ChevronGeometry.Cap.Flat

            bgFill: Settings.colors.bgTint2

            Percentage {
                visible: !Core.Audio.sink.muted

                height: root.height
                value: Core.Audio.sink.value
            }

            Text {
                visible: Core.Audio.sink.muted
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Settings.inducedVerticalOffset

                text: "MUTED"
                color: Settings.colors.accentError
                font.family: Settings.labelFontFamily
                font.pixelSize: Settings.smallCapsFontSize
                font.weight: Font.Bold
            }
        }
    }
}
