import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls

import qs.core as Core
import "vitalsviewer" as VitalsUI

// PopoutHost supplies the background, blur, border, and reveal animation.
Controls.Pane {
    id: root

    implicitWidth: VitalsUI.Configuration.widgetWidth
    implicitHeight: Math.max(VitalsUI.Configuration.widgetHeight, implicitContentHeight + topPadding + bottomPadding)
    verticalPadding: WidgetConfiguration.dropDownWindowPadding
    background: null

    // PopoutHost unloads this pane after closing; release singleton demand
    // explicitly because destroying a Binding does not restore its value.
    Component.onDestruction: {
        Core.SystemStats.detailActive = false
        Core.SystemStats.igpuStress.active = false
        Core.SystemStats.storageUsage.active = false
    }

    Binding {
        target: Core.SystemStats
        property: "detailActive"
        value: root.visible
    }

    Binding {
        target: Core.SystemStats.igpuStress
        property: "active"
        value: root.visible
    }

    Binding {
        target: Core.SystemStats.storageUsage
        property: "active"
        value: root.visible
    }

    contentItem: ColumnLayout {
        spacing: WidgetConfiguration.sectionVSpacing

        VitalsUI.SystemInfoRow {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.leftMargin: VitalsUI.Configuration.gaugeContainerPaddingX
            Layout.rightMargin: VitalsUI.Configuration.gaugeContainerPaddingX
            spacing: 0

            VitalsUI.CPUGauge {
                id: cpu
            }

            Item {
                Layout.fillWidth: true
            }

            VitalsUI.MEMGauge {
                id: mem
            }
        }

        RowLayout {
            id: coreEntries
            Layout.fillWidth: true
            Layout.leftMargin: VitalsUI.Configuration.coresContainerPaddingX
            Layout.rightMargin: VitalsUI.Configuration.coresContainerPaddingX
            Layout.topMargin: VitalsUI.Configuration.coresContainerMarginTop
            Layout.bottomMargin: VitalsUI.Configuration.coresContainerMarginBottom
            uniformCellSizes: true
            spacing: 0

            Repeater {
                model: VitalsUI.Configuration.coreEntryColumns

                delegate: ColumnLayout {
                    id: threadColumn
                    required property var modelData

                    Layout.fillWidth: true
                    // Let the column grow beyond its content-sized entries.
                    Layout.maximumWidth: Infinity
                    spacing: VitalsUI.Configuration.coreEntriesVSpacing

                    Repeater {
                        model: threadColumn.modelData

                        delegate: VitalsUI.CoreEntry {
                            required property var modelData
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignHCenter

                            coreName: "C" + modelData.thread
                            stress: Core.SystemStats.cpuStress.threads[modelData.thread]?.value ?? NaN
                            temperature: Core.SystemStats.cpuTemperature.cores[modelData.temperatureCore]?.value ?? NaN
                        }
                    }
                }
            }
        }
    }
}
