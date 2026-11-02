import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

import qs

Item {
    id: root

    property string imagePath
    property url imageSource: imagePath
    property real previewWidth
    property real decodeWidth: previewWidth
    property real previewBorderRadius
    property int labelFontSz: Settings.smallCapsFontSize
    property string labelFontFamily: Settings.labelFontFamily
    property color labelColor: Settings.colors.foreground.main
    property string fitMode: "PreserveAspectCrop"

    readonly property real previewHeight: previewWidth * 9 / 16
    readonly property bool ready: img.status === Image.Ready

    readonly property string labelText: {
        if (!imagePath) return ""
        var name = imagePath.split("/").pop().split("\\").pop()
        var dot = name.lastIndexOf(".")
        return (dot > 0 ? name.substring(0, dot) : name).toUpperCase()
    }

    implicitWidth: previewWidth
    implicitHeight: previewWrapper.implicitHeight

    ColumnLayout {
        id: previewWrapper
        width: root.width
        spacing: Configuration.imagePreviewVSpacing

        ClippingRectangle {
            implicitWidth: root.previewWidth
            implicitHeight: root.previewHeight
            radius: root.previewBorderRadius
            color: "transparent"

            Image {
                id: img
                anchors.fill: parent
                source: root.imageSource
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                sourceSize.width: root.decodeWidth * 2
                sourceSize.height: root.decodeWidth * 2 * 9 / 16

                fillMode: {
                    switch (root.fitMode) {
                    case "Stretch":             return Image.Stretch
                    case "PreserveAspectFit":   return Image.PreserveAspectFit
                    case "Pad":                 return Image.Pad
                    case "PreserveAspectCrop":
                    default:                    return Image.PreserveAspectCrop
                    }
                }
            }
        }

        Text {
            id: label
            Layout.maximumWidth: root.previewWidth
            Layout.alignment: Qt.AlignHCenter
            text: root.labelText
            color: root.labelColor

            font {
                pixelSize: root.labelFontSz
                family: root.labelFontFamily
                bold: true
                capitalization: Font.AllUppercase
            }

            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
