import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import qs
import qs.core as Core
import qs.components

Item {
    id: root
    implicitWidth: circle.width
    implicitHeight: circle.height

    readonly property color swapColor: shiftHue(Configuration.memGaugeColorHueShifts[0], Settings.colors.foreground.accent)
    readonly property color storageColor: shiftHue(Configuration.memGaugeColorHueShifts[1], Settings.colors.foreground.accent)
    readonly property color ramColor: Settings.colors.foreground.accent

    Circle {
        paintInForeground: false
        anchors.centerIn: parent
        diameter: Configuration.gaugeSz - Configuration.gaugeInnerDiameterOffset
        color: Settings.colors.background.tint1

        ColumnLayout {
            id: stats
            spacing: 0
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
                topMargin: Configuration.gaugeStatsPaddingTop
                bottomMargin: Configuration.gaugeStatsPaddingBottom
            }

            Text {
                id: ramLabel
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Configuration.gaugeLabelBottomMargin

                text: "RAM"
                font.family: Settings.labelFontFamily
                font.weight: Font.Bold
                font.pixelSize: Configuration.gaugeLabelFontSz
                font.letterSpacing: Configuration.gaugeLabelLetterSpacing
                color: Settings.colors.foreground.main
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                id: ramUsage
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignHCenter
                spacing: Configuration.memGaugeMainMetricHSpacing

                Text {
                    Layout.alignment: Qt.AlignBaseline
                    text: root.ramUsageText()
                    font.family: Settings.labelFontFamily
                    font.weight: Font.Bold
                    font.pixelSize: Configuration.gaugeMainMetricFontSz
                    font.letterSpacing: Configuration.memGaugeMainLetterSpacing
                    color: Settings.colors.foreground.main
                }

                Text {
                    Layout.alignment: Qt.AlignBaseline
                    text: "GiB"
                    font.family: Settings.labelFontFamily
                    font.weight: Font.Bold
                    font.pixelSize: Configuration.gaugeMainUnitFontSz
                    font.letterSpacing: Configuration.memGaugeMainUnitLetterSpacing
                    color: root.ramColor
                }
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                spacing: Configuration.gaugeSecondaryMetricsVSpacing

                BackgroundRectangle {
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: swap.implicitWidth + Configuration.gaugeSecondaryMetricPaddingX
                    implicitHeight: swap.implicitHeight + Configuration.gaugeSecondaryMetricPaddingY
                    color: Settings.colors.background.main
                    radius: width / 2

                    RowLayout {
                        id: swap
                        anchors.centerIn: parent
                        spacing: Configuration.gaugeSecondaryMetricHSpacing

                        Circle {
                            diameter: Configuration.gaugeSecondaryMetricDotSz
                            color: root.storageColor
                        }

                        Text {
                            text: "Storage"
                            font.family: Settings.labelFontFamily
                            font.pixelSize: Configuration.gaugeSecondaryMetricFontSz
                            color: root.storageColor
                        }
                    }
                }

                BackgroundRectangle {
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: storage.implicitWidth + Configuration.gaugeSecondaryMetricPaddingX
                    implicitHeight: storage.implicitHeight + Configuration.gaugeSecondaryMetricPaddingY
                    color: Settings.colors.background.main
                    radius: width / 2

                    RowLayout {
                        id: storage
                        anchors.centerIn: parent
                        spacing: Configuration.gaugeSecondaryMetricHSpacing

                        Circle {
                            diameter: Configuration.gaugeSecondaryMetricDotSz
                            color: root.swapColor
                        }

                        Text {
                            text: "swap"
                            font.family: Settings.labelFontFamily
                            font.pixelSize: Configuration.gaugeSecondaryMetricFontSz
                            color: root.swapColor
                        }
                    }
                }
            }
        }
    }

    Shape {
        id: circleBg
        anchors.fill: parent
        implicitWidth: Configuration.gaugeSz
        implicitHeight: Configuration.gaugeSz
        preferredRendererType: Shape.CurveRenderer
        property real radius: (Math.min(width, height) - Configuration.gaugeArcStrokeWidth) / 2
        opacity: Configuration.gaugeArcBackgroundOpacity

        ShapePath {
            strokeColor: root.swapColor
            strokeWidth: Configuration.gaugeArcStrokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: circle.radius
                radiusY: circle.radius
                startAngle: 30 + Configuration.gaugeArcGapAngle / 2
                sweepAngle: 120 - Configuration.gaugeArcGapAngle
            }
        }

        ShapePath {
            strokeColor: root.ramColor
            strokeWidth: Configuration.gaugeArcStrokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: circle.radius
                radiusY: circle.radius
                startAngle: -90 + Configuration.gaugeArcGapAngle / 2
                sweepAngle: 120 - Configuration.gaugeArcGapAngle
            }
        }

        ShapePath {
            strokeColor: root.storageColor
            strokeWidth: Configuration.gaugeArcStrokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: circle.radius
                radiusY: circle.radius
                startAngle: 150 + Configuration.gaugeArcGapAngle / 2
                sweepAngle: 120 - Configuration.gaugeArcGapAngle
            }
        }
    }

    Shape {
        id: circle
        anchors.fill: parent
        implicitWidth: Configuration.gaugeSz
        implicitHeight: Configuration.gaugeSz
        preferredRendererType: Shape.CurveRenderer
        property real radius: (Math.min(width, height) - Configuration.gaugeArcStrokeWidth) / 2

        ShapePath {
            strokeColor: swapArc.sweepAngle > 0 ? root.swapColor : "transparent"
            strokeWidth: Configuration.gaugeArcStrokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: swapArc
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: circle.radius
                radiusY: circle.radius
                startAngle: 30 + Configuration.gaugeArcGapAngle / 2
                sweepAngle: root.valueToSweep(Core.SystemStats.ramStress.swapPercentage, 0, 100)
            }
        }

        ShapePath {
            strokeColor: ramArc.sweepAngle > 0 ? root.ramColor : "transparent"
            strokeWidth: Configuration.gaugeArcStrokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: ramArc
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: circle.radius
                radiusY: circle.radius
                startAngle: -90 + Configuration.gaugeArcGapAngle / 2
                sweepAngle: root.valueToSweep(Core.SystemStats.ramStress.overall.value, 0, 100)
            }
        }

        ShapePath {
            strokeColor: storageArc.sweepAngle > 0 ? root.storageColor : "transparent"
            strokeWidth: Configuration.gaugeArcStrokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: storageArc
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: circle.radius
                radiusY: circle.radius
                startAngle: 150 + Configuration.gaugeArcGapAngle / 2
                sweepAngle: root.valueToSweep(Core.SystemStats.storageUsage.overall.value, 0, 100)
            }
        }
    }

    // ────── Helper Functions ──────
    function ramUsageText(): string {
        const gibibytes = Core.SystemStats.ramStress.usedBytes / (1024 * 1024 * 1024)
        return gibibytes.toFixed(Configuration.memGaugeMainMetricDecimals)
    }

    function valueToSweep(value: real, minimum: real, maximum: real): real {
        if (!Number.isFinite(value) || maximum <= minimum)
            return 0

        const progress = Math.max(0, Math.min(1, (value - minimum) / (maximum - minimum)))
        return Math.max(0, 120 - Configuration.gaugeArcGapAngle) * progress
    }

    function shiftHue(hueShift: real, sourceColor = Settings.colors.foreground.accent): color {
        const hue = Math.max(0, sourceColor.hsvHue) + hueShift / 360
        return Qt.hsva((hue % 1 + 1) % 1, sourceColor.hsvSaturation, sourceColor.hsvValue, sourceColor.a)
    }
}
