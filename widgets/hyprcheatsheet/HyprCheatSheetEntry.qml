import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls

import qs
import qs.components

RowLayout {
    id: root

    required property var keybinds
    required property string label

    spacing: Configuration.entryHSeparator

    RowLayout {
        id: entryKeybinds

        Layout.minimumWidth: implicitWidth
        spacing: Configuration.entryKeybindsHSpacing

        Repeater {
            model: root.keybinds

            RowLayout {
                id: keybind

                required property int index
                required property var modelData

                spacing: Configuration.entryKeybindsHSpacing

                Text {
                    visible: index > 0
                    text: Configuration.entryKeybindsSeparator
                    color: Settings.colors.foreground.main
                    font.family: Settings.labelFontFamily
                    font.pixelSize: Configuration.entryKeyFontSz
                }

                Controls.Pane {
                    horizontalPadding: Configuration.entryKeyPaddingX + Configuration.entryKeyStrokeSz
                    verticalPadding: Configuration.entryKeyPaddingY + Configuration.entryKeyStrokeSz
                    implicitWidth: Math.max(implicitHeight, implicitContentWidth + leftPadding + rightPadding)
                    implicitHeight: implicitContentHeight + topPadding + bottomPadding

                    background: BackgroundRectangle {
                        color: "transparent"
                        radius: Configuration.entryKeyRadius
                        border.width: Configuration.entryKeyStrokeSz
                        border.color: Settings.colors.background.highlight
                    }

                    contentItem: RowLayout {
                        spacing: Configuration.entryKeyMultipleHSpacing

                        Repeater {
                            model: root.keyValues(keybind.modelData)

                            RowLayout {
                                required property int index
                                required property var modelData

                                Layout.alignment: Qt.AlignCenter
                                spacing: Configuration.entryKeyMultipleHSpacing

                                Text {
                                    visible: index > 0
                                    text: Configuration.entryKeyMultipleSeparator
                                    color: Settings.colors.foreground.main
                                    font.family: Settings.iconFontFamily
                                    font.pixelSize: Configuration.entryKeyFontSz
                                }

                                Text {
                                    text: modelData
                                    color: Settings.colors.foreground.main
                                    font.family: Settings.iconFontFamily
                                    font.pixelSize: Configuration.entryKeyFontSz
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: root.label
        color: Settings.colors.foreground.main
        font.family: Settings.labelFontFamily
        font.pixelSize: Configuration.entryLabelFontSz
        wrapMode: Text.Wrap
    }

    // ────── Helper Functions ──────
    function keyValues(key): var {
        // Repeater can expose nested arrays as QML sequences rather than JS arrays.
        return typeof key === "string"
            ? [key]
            : Array.from(key)
    }
}
