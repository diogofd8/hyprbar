import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs
import qs.components
import qs.core as Core

Item {
    id: root
    readonly property real profileInset: userProfile.width / 2 + Configuration.sysInfoRowHSpacing

    implicitWidth: 2 * Math.max(centerLeft.implicitWidth, uptimeInfo.implicitWidth)
    implicitHeight: Math.max(userProfile.height, centerLeft.implicitHeight, uptimeInfo.implicitHeight)

    Component.onCompleted: root.refreshIfVisible()
    onVisibleChanged: root.refreshIfVisible()

    Timer {
        interval: root.uptimeRefreshInterval()
        running: root.visible
        repeat: true
        onTriggered: Core.SystemInfo.refreshUptime()
    }

    ClippingRectangle {
        id: userProfile
        anchors.centerIn: parent
        width: Configuration.sysProfileImgSz
        height: width
        radius: width / 2
        color: Settings.colors.fgMain
        z: 1

        Image {
            anchors.fill: parent
            source: Core.SystemInfo.userIcon
            sourceSize.width: Configuration.sysProfileImgSz * Screen.devicePixelRatio
            sourceSize.height: Configuration.sysProfileImgSz * Screen.devicePixelRatio
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }

    RowLayout {
        id: centerLeft
        anchors.right: userProfile.horizontalCenter
        anchors.verticalCenter: userProfile.verticalCenter
        spacing: Configuration.sysInfoRowHSpacing - Core.ChevronGeometry.calcCapWidth(linuxDistro.height)

        Chevron {
            id: hostnameInfo
            Layout.preferredHeight: linuxDistro.implicitHeight
            contentLeftPadding: Configuration.sysCompositeItemHSpacing
            contentRightPadding: Configuration.sysCompositeItemHSpacing

            leftCap: Core.ChevronGeometry.Cap.Point
            rightCap: Core.ChevronGeometry.Cap.Notch
            bgFill: Settings.colors.bgTint1

            Text {
                text: Core.SystemInfo.hostname
                font.family: Settings.labelFontFamily
                font.pixelSize: Configuration.sysEntryFontSz
                font.weight: Font.Bold
                color: Settings.colors.fgMain
            }
        }

        Chevron {
            id: desktopEnvironment
            contentLeftPadding: Configuration.sysCompositeItemHSpacing
            contentRightPadding: Configuration.sysCompositeItemHSpacing

            leftCap: Core.ChevronGeometry.Cap.Point
            rightCap: Core.ChevronGeometry.Cap.Notch

            bgFill: Settings.colors.bgTint2

            Glyph {
                icon: Configuration.desktopIcon(Core.SystemInfo.desktop)
                iconSize: Configuration.sysEntryIconSz
                useMetrics: true
                verticalOffset: 0
            }
        }

        Chevron {
            id: linuxDistro
            contentLeftPadding: 1 + Configuration.sysCompositeItemHSpacing
            contentRightPadding: -1 + Configuration.sysCompositeItemHSpacing + root.profileInset

            leftCap: Core.ChevronGeometry.Cap.Point
            rightCap: Core.ChevronGeometry.Cap.Flat

            bgFill: Settings.colors.bgTint3

            Glyph {
                icon: root.distroIcon()
                iconSize: Configuration.sysEntryIconSz
                useMetrics: true
                verticalOffset: 0
            }
        }
    }

    RowLayout {
        id: centerRight
        anchors.left: userProfile.horizontalCenter
        anchors.verticalCenter: userProfile.verticalCenter
        spacing: Configuration.sysInfoRowHSpacing - Core.ChevronGeometry.calcCapWidth(linuxDistro.height)

        Chevron {
            id: sysClock
            contentLeftPadding: Configuration.sysCompositeItemHSpacing + root.profileInset
            contentRightPadding: Configuration.sysCompositeItemHSpacing

            leftCap: Core.ChevronGeometry.Cap.Flat
            rightCap: Core.ChevronGeometry.Cap.Point

            bgFill: Settings.colors.bgTint3

            Glyph {
                icon: Configuration.sysClockIcon
                iconSize: Configuration.sysEntryIconSz
                useMetrics: true
                verticalOffset: 0
            }
        }

        Chevron {
            id: uptimeInfo
            Layout.preferredHeight: sysClock.implicitHeight
            contentLeftPadding: Configuration.sysCompositeItemHSpacing
            contentRightPadding: Configuration.sysCompositeItemHSpacing

            leftCap: Core.ChevronGeometry.Cap.Notch
            rightCap: Core.ChevronGeometry.Cap.Point

            bgFill: Settings.colors.bgTint2

            RowLayout {
                spacing: Configuration.sysCompositeItemHSpacing

                Text {
                    visible: Core.SystemInfo.uptimeDays
                    text: Core.SystemInfo.uptimeDays + "d"
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.sysEntryFontSz
                    font.weight: Font.Bold
                    color: Settings.colors.fgMain
                }

                Text {
                    text: Core.SystemInfo.uptimeHours + "h"
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.sysEntryFontSz
                    font.weight: Font.Bold
                    color: Settings.colors.fgMain
                }

                Text {
                    text: Core.SystemInfo.uptimeMinutes + "m"
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.sysEntryFontSz
                    font.weight: Font.Bold
                    color: Settings.colors.fgMain
                }
            }
        }
    }

    function refreshIfVisible(): void {
        if (root.visible)
            Core.SystemInfo.refresh()
    }

    function uptimeRefreshInterval(): int {
        const remaining = 60 - Core.SystemInfo.uptimeSeconds % 60
        return Math.max(20, Math.ceil(remaining * 1000) + 20)
    }

    function distroIcon(): string {
        return Configuration.sysDistroIcon[Core.SystemInfo.osId] ?? Configuration.sysDistroIcon.tux
    }
}
