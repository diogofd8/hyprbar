import QtQuick
import QtQuick.Layouts

import qs
import qs.components
import qs.core as Core
import qs.widgets

ColumnLayout {
    id: root
    objectName: "matugenPage"
    spacing: 0

    property bool active: false
    property string monitorName: ""
    property bool selectionInitialized: false
    property Item selectedPreview: null
    readonly property string selectedImage: selectedPreview ? selectedPreview.imagePath : ""
    readonly property bool canApply: active && Core.Wallpapers.available && !Core.Wallpapers.refreshing
        && !Core.ThemeControl.busy && monitorName.length > 0 && selectedImage.length > 0
        && selectedPreview !== null && selectedPreview.ready
        && !(Core.SystemPalette.source === "matugen"
            && Core.Wallpapers.normalizePath(selectedImage) === Core.Wallpapers.normalizePath(Core.SystemPalette.image)
            && Core.Wallpapers.normalizePath(selectedImage) === Core.Wallpapers.currentWallpaper)

    function selectCurrentWallpaper(): void {
        if (!active || selectionInitialized || !Core.Wallpapers.ready || !Core.Wallpapers.refreshComplete || wallpapers.count === 0)
            return
        let selected = 0
        for (let index = 0; index < Core.Wallpapers.count; ++index) {
            if (Core.Wallpapers.normalizePath(Core.Wallpapers.fileAt(index)) === Core.Wallpapers.currentWallpaper) {
                selected = index
                break
            }
        }
        wallpapers.currentIndex = selected
        wallpapers.positionViewAtIndex(selected, PathView.SnapPosition)
        selectionInitialized = true
    }

    onActiveChanged: {
        selectionInitialized = false
        if (active) Qt.callLater(selectCurrentWallpaper)
    }
    onMonitorNameChanged: selectionInitialized = false

    Binding {
        target: Core.Wallpapers
        property: "active"
        value: true
        when: root.active
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: Core.Wallpapers
        property: "monitorName"
        value: root.monitorName
        when: root.active
        restoreMode: Binding.RestoreBindingOrValue
    }

    Connections {
        target: Core.Wallpapers
        function onReadyChanged(): void { Qt.callLater(root.selectCurrentWallpaper) }
        function onRefreshed(): void { Qt.callLater(root.selectCurrentWallpaper) }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Configuration.themePageMarginX
        Layout.rightMargin: Configuration.themePageMarginX
        spacing: WidgetConfiguration.mainRowHSpacing

        Text {
            text: "WALLPAPER"
            font.family: Settings.labelFontFamily
            font.pixelSize: WidgetConfiguration.sectionRowLabelFontSz
            font.bold: true
            color: Settings.colors.foreground.main
        }

        Item {
            Layout.fillWidth: true
        }

        ChevronButton {
            id: applyBtn
            objectName: "applyWallpaperButton"
            bgFill: Settings.colors.background.accent
            hoverOpacity: Settings.colors.background.hoverOpacityStrong
            enabled: root.canApply
            opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity
            onLeftClicked: Core.ThemeControl.applyWallpaper(root.selectedImage, root.monitorName)

            implicitHeight: applyRow.implicitHeight + Configuration.applyBtnPaddingY
            contentLeftPadding: Configuration.applyBtnPaddingX
            contentRightPadding: Configuration.applyBtnPaddingX
            leftCap: Core.ChevronGeometry.Cap.Point
            rightCap: Core.ChevronGeometry.Cap.Point

            RowLayout {
                id: applyRow
                spacing: Configuration.applyBtnHSpacing

                Glyph {
                    id: applyIcon

                    icon: Configuration.applyIcon
                    iconSize: Configuration.btnsIconSz
                    color: Settings.colors.foreground.contrast
                }

                Text {
                    id: applyText

                    text: "APPLY"
                    color: Settings.colors.foreground.contrast
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Settings.smallCapsFontSize
                    font.weight: Font.Bold
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        id: carousel
        Layout.alignment: Qt.AlignHCenter
        spacing: Configuration.navigationContextHSpacing

        Item {
            height: prevBtnIcon.implicitHeight + Configuration.navigationBtnsPaddingY
            width: prevBtn.implicitWidth

            ChevronButton {
                id: prevBtn
                anchors.centerIn: parent
                height: parent.height
                contentLeftPadding: Configuration.navigationBtnsPaddingX
                contentRightPadding: Configuration.navigationBtnWeakMarginSz + Configuration.navigationBtnsPaddingX

                leftCap: Core.ChevronGeometry.Cap.Point
                rightCap: Core.ChevronGeometry.Cap.Flat

                bgFill: Settings.colors.background.tint2
                enabled: root.active && wallpapers.count > 1 && !Core.ThemeControl.busy
                opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity
                onLeftClicked: wallpapers.decrementCurrentIndex()

                Glyph {
                    id: prevBtnIcon
                    verticalOffset: 0

                    icon: Configuration.navigationIcon[0]
                    iconSize: Configuration.navigationBtnsSz
                    color: Settings.colors.foreground.main
                }
            }
        }

        PathView {
            id: wallpapers
            objectName: "wallpaperCarousel"
            implicitWidth: Configuration.imagePreviewMainWidth + 2 * Configuration.imagePreviewSecWidth
                + 2 * Configuration.imagePreviewHSpacing
            implicitHeight: Math.ceil(Configuration.imagePreviewMainWidth * 9 / 16
                + Configuration.imagePreviewVSpacing + previewMetrics.height)
            model: root.active ? Core.Wallpapers.model : null
            pathItemCount: 3
            cacheItemCount: 2
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightMoveDuration: Motion.normalMs
            interactive: false
            clip: true
            onCountChanged: Qt.callLater(root.selectCurrentWallpaper)

            FontMetrics {
                id: previewMetrics
                font.family: Settings.labelFontFamily
                font.pixelSize: Configuration.imagePreviewLabelFontSz
                font.bold: true
            }

            delegate: ImagePreview {
                id: preview
                required property string filePath
                required property url fileUrl
                imagePath: filePath
                imageSource: fileUrl
                previewWidth: PathView.previewWidth
                // Decode at one fixed resolution, independently of animation.
                decodeWidth: Configuration.imagePreviewMainWidth
                labelFontSz: Configuration.imagePreviewLabelFontSz
                previewBorderRadius: Configuration.imagePreviewRadius
                opacity: PathView.onPath ? PathView.previewOpacity : 0

                Binding {
                    // Publish after the delegate's model roles are available.
                    target: root
                    property: "selectedPreview"
                    value: preview
                    when: preview.PathView.isCurrentItem
                    restoreMode: Binding.RestoreBindingOrValue
                }
            }

            path: Path {
                startX: -Configuration.imagePreviewSecWidth / 2
                startY: wallpapers.height / 2
                PathAttribute { name: "previewWidth"; value: Configuration.imagePreviewSecWidth }
                PathAttribute { name: "previewOpacity"; value: 0 }
                PathLine { x: Configuration.imagePreviewSecWidth / 2; y: wallpapers.height / 2 }
                PathPercent { value: 1 / 6 }
                PathAttribute { name: "previewWidth"; value: Configuration.imagePreviewSecWidth }
                PathAttribute { name: "previewOpacity"; value: 1 }
                PathLine { x: wallpapers.width / 2; y: wallpapers.height / 2 }
                PathPercent { value: 0.5 }
                PathAttribute { name: "previewWidth"; value: Configuration.imagePreviewMainWidth }
                PathLine { x: wallpapers.width - Configuration.imagePreviewSecWidth / 2; y: wallpapers.height / 2 }
                PathPercent { value: 5 / 6 }
                PathAttribute { name: "previewWidth"; value: Configuration.imagePreviewSecWidth }
                PathAttribute { name: "previewOpacity"; value: 1 }
                PathLine { x: wallpapers.width + Configuration.imagePreviewSecWidth / 2; y: wallpapers.height / 2 }
                PathAttribute { name: "previewWidth"; value: Configuration.imagePreviewSecWidth }
                PathAttribute { name: "previewOpacity"; value: 0 }
            }

            Text {
                anchors.centerIn: parent
                visible: root.active && Core.Wallpapers.refreshComplete && Core.Wallpapers.count === 0
                text: "No readable wallpapers in the configured directory."
                color: Settings.colors.foreground.main
                font.family: Settings.labelFontFamily
                font.pixelSize: Configuration.imagePreviewLabelFontSz
            }
        }

        Item {
            height: nextBtnIcon.implicitHeight + Configuration.navigationBtnsPaddingY
            width: nextBtn.implicitWidth

            ChevronButton {
                id: nextBtn
                anchors.centerIn: parent
                height: parent.height
                contentLeftPadding: Configuration.navigationBtnWeakMarginSz + Configuration.navigationBtnsPaddingX
                contentRightPadding: Configuration.navigationBtnsPaddingX

                leftCap: Core.ChevronGeometry.Cap.Flat
                rightCap: Core.ChevronGeometry.Cap.Point

                bgFill: Settings.colors.background.tint2
                enabled: root.active && wallpapers.count > 1 && !Core.ThemeControl.busy
                opacity: enabled ? 1 : Settings.colors.foreground.disabledOpacity
                onLeftClicked: wallpapers.incrementCurrentIndex()

                Glyph {
                    id: nextBtnIcon
                    verticalOffset: 0

                    icon: Configuration.navigationIcon[1]
                    iconSize: Configuration.navigationBtnsSz
                    color: Settings.colors.foreground.main
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
