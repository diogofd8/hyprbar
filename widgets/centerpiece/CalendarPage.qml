import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs
import qs.components
import qs.widgets as Widgets

Item {
    id: root

    implicitWidth: pageLayout.implicitWidth
    implicitHeight: pageLayout.implicitHeight

    property date displayedMonth: new Date()
    readonly property date today: {
        const now = clock.date
        return new Date(now.getFullYear(), now.getMonth(), now.getDate())
    }
    readonly property bool isCurrentMonth: calendarModel.month === root.today.getMonth()
        && calendarModel.year === root.today.getFullYear()

    // Include complete Monday-Sunday weeks, extending to the configured minimum.
    readonly property date firstVisibleDate: {
        const first = new Date(calendarModel.year, calendarModel.month, 1)
        first.setDate(1 - (first.getDay() + 6) % 7)
        return first
    }
    readonly property date nextVisibleDate: {
        const last = new Date(calendarModel.year, calendarModel.month + 1, 0)
        last.setDate(last.getDate() + 7 - (last.getDay() + 6) % 7)
        const minimumEnd = new Date(root.firstVisibleDate)
        minimumEnd.setDate(minimumEnd.getDate() + 7 * Configuration.calendarMinimumRows)
        return minimumEnd > last ? minimumEnd : last
    }

    function changeMonth(offset: int): void {
        root.displayedMonth = new Date(calendarModel.year, calendarModel.month + offset, 1)
    }

    function resetMonth(): void {
        root.displayedMonth = new Date(root.today.getFullYear(), root.today.getMonth(), 1)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    // Use Qt's date model without its automatic six-row delegate sizing.
    // The separate GridLayout owns the weekday header and all day-cell geometry.
    MonthGrid {
        id: calendarModel

        visible: false
        month: root.displayedMonth.getMonth()
        year: root.displayedMonth.getFullYear()
        locale: Qt.locale("C")
        padding: 0
        background: null
        delegate: null
        contentItem: Item {}
    }

    RowLayout {
        id: pageLayout

        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
        }

        GridLayout {
            id: calendarGrid

            columns: 7
            columnSpacing: Configuration.calendarCellSpacing
            rowSpacing: Configuration.calendarCellSpacing
            uniformCellWidths: true
            uniformCellHeights: true

            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Configuration.calendarPaddingX
            Layout.rightMargin: Configuration.calendarPaddingX
            Layout.topMargin: Configuration.calendarPaddingY
            Layout.bottomMargin: Configuration.calendarPaddingY

            Repeater {
                model: 7

                delegate: CalendarCell {
                    required property int index

                    text: calendarModel.locale.dayName((index + calendarModel.locale.firstDayOfWeek) % 7, Locale.ShortFormat).toUpperCase()
                    heading: true
                }
            }

            Repeater {
                model: calendarModel.source

                delegate: CalendarCell {
                    required property var model

                    readonly property date cellDate: new Date(model.year, model.month, model.day)

                    text: model.day
                    adjacentMonth: model.month !== calendarModel.month || model.year !== calendarModel.year
                    selected: model.year === root.today.getFullYear() && model.month === root.today.getMonth() && model.day === root.today.getDate()
                    // The native model supplies all six weeks, including a leading week for Monday starts.
                    visible: Configuration.calendarMinimumRows >= 6 || (cellDate >= root.firstVisibleDate && cellDate < root.nextVisibleDate)
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: Configuration.calendarNavBtnSpacing

            Repeater {
                model: [
                    {icon: Configuration.calendarNavigationIcon.previousMonth, offset: -1},
                    {icon: Configuration.calendarNavigationIcon.nextMonth, offset: 1},
                    {icon: Configuration.calendarNavigationIcon.currentMonth, offset: 0}
                ]

                delegate: SquaredButton {
                    required property var modelData

                    Layout.alignment: Qt.AlignHCenter
                    glyph: modelData.icon
                    glyphSize: Widgets.WidgetConfiguration.widgetMainIconSz
                    padding: Configuration.calendarNavBtnPadding
                    useMetrics: true

                    visible: modelData.offset !== 0 || !root.isCurrentMonth

                    onLeftClicked: {
                        if (modelData.offset === 0)
                            root.resetMonth()
                        else
                            root.changeMonth(modelData.offset)
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: calendarModel.month + 1
                    horizontalAlignment: Text.AlignHCenter
                    color: Settings.colors.fgMain
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.mainTextFontSz
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: calendarModel.year
                    horizontalAlignment: Text.AlignHCenter
                    color: Settings.colors.fgMain
                    opacity: Settings.colors.dimOpacity
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.subTextFontSz
                }
            }
        }
    }
}
