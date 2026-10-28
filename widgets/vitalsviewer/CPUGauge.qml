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

    readonly property color cpuColor: shiftHue(Configuration.cpuGaugeColorHueShifts[0], Settings.colors.foreground.accent)
    readonly property color igpuColor: shiftHue(Configuration.cpuGaugeColorHueShifts[1], Settings.colors.foreground.accent)
    readonly property color temperatureColor: Settings.colors.foreground.accent

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
                id: cpuLabel
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Configuration.gaugeLabelBottomMargin

                text: "CPU"
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
                id: cpuUsage
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignBaseline
                    text: Math.round(Core.SystemStats.cpuTemperature.overall.value)
                    font.family: Settings.labelFontFamily
                    font.weight: Font.Bold
                    font.pixelSize: Configuration.gaugeMainMetricFontSz
                    color: Settings.colors.foreground.main
                }

                Text {
                    Layout.alignment: Qt.AlignBaseline
                    text: "ºC"
                    font.family: Settings.labelFontFamily
                    font.weight: Font.Bold
                    font.pixelSize: Configuration.gaugeMainUnitFontSz
                    font.letterSpacing: Configuration.cpuGaugeMainUnitLetterSpacing
                    color: root.temperatureColor
                }
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                spacing: Configuration.gaugeSecondaryMetricsVSpacing

                BackgroundRectangle {
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: igpu.implicitWidth + Configuration.gaugeSecondaryMetricPaddingX
                    implicitHeight: igpu.implicitHeight + Configuration.gaugeSecondaryMetricPaddingY
                    color: Settings.colors.background.main
                    radius: width / 2

                    RowLayout {
                        id: igpu
                        anchors.centerIn: parent
                        spacing: Configuration.gaugeSecondaryMetricHSpacing

                        Circle {
                            diameter: Configuration.gaugeSecondaryMetricDotSz
                            color: root.igpuColor
                        }

                        Text {
                            text: "iGPU"
                            font.family: Settings.labelFontFamily
                            font.pixelSize: Configuration.gaugeSecondaryMetricFontSz
                            color: root.igpuColor
                        }
                    }
                }

                BackgroundRectangle {
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: cpu.implicitWidth + Configuration.gaugeSecondaryMetricPaddingX
                    implicitHeight: cpu.implicitHeight + Configuration.gaugeSecondaryMetricPaddingY
                    color: Settings.colors.background.main
                    radius: width / 2

                    RowLayout {
                        id: cpu
                        anchors.centerIn: parent
                        spacing: Configuration.gaugeSecondaryMetricHSpacing

                        Circle {
                            diameter: Configuration.gaugeSecondaryMetricDotSz
                            color: root.cpuColor
                        }

                        Text {
                            text: "CPU"
                            font.family: Settings.labelFontFamily
                            font.pixelSize: Configuration.gaugeSecondaryMetricFontSz
                            color: root.cpuColor
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
            strokeColor: root.cpuColor
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
            strokeColor: root.igpuColor
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
            strokeColor: root.temperatureColor
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
            strokeColor: cpuArc.sweepAngle > 0 ? root.cpuColor : "transparent"
            strokeWidth: Configuration.gaugeArcStrokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: cpuArc
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: circle.radius
                radiusY: circle.radius
                startAngle: 30 + Configuration.gaugeArcGapAngle / 2
                sweepAngle: root.valueToSweep(Core.SystemStats.cpuStress.overall.value, 0, 100)
            }
        }

        ShapePath {
            strokeColor: igpuArc.sweepAngle > 0 ? root.igpuColor : "transparent"
            strokeWidth: Configuration.gaugeArcStrokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: igpuArc
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: circle.radius
                radiusY: circle.radius
                startAngle: -90 + Configuration.gaugeArcGapAngle / 2
                sweepAngle: root.valueToSweep(Core.SystemStats.igpuStress.overall.value, 0, 100)
            }
        }

        ShapePath {
            strokeColor: temperatureArc.sweepAngle > 0 ? root.temperatureColor : "transparent"
            strokeWidth: Configuration.gaugeArcStrokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: temperatureArc
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: circle.radius
                radiusY: circle.radius
                startAngle: 150 + Configuration.gaugeArcGapAngle / 2
                sweepAngle: root.valueToSweep(Core.SystemStats.cpuTemperature.overall.value, 0, Configuration.cpuGaugeTemperatureMaxValue)
            }
        }
    }

    // ────── Helper Functions ──────
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
