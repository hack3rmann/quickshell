import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.bar

PanelWindow {
    id: root

    property bool opened: false

    signal closeRequested

    readonly property real btnWidth: Math.round(140 * Theme.uiScale / 1.5)
    readonly property real btnHeight: Math.round(120 * Theme.uiScale / 1.5)
    readonly property real panelPad: Theme.menuPad * 2

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: true

    WlrLayershell.namespace: "quickshell-powermenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    BackgroundEffect.blurRegion: root.opened ? blurRegion : null

    mask: root.opened ? fullMask : emptyMask

    Region {
        id: emptyMask
    }

    Region {
        id: fullMask
        item: maskCover
    }

    Region {
        id: blurRegion
        item: panel
        radius: Theme.radius
    }

    Item {
        id: maskCover
        anchors.fill: parent
    }

    function requestClose() {
        root.closeRequested();
    }

    function runAction(argv) {
        Quickshell.execDetached(argv);
        root.requestClose();
    }

    readonly property var actions: [
        {
            id: "shutdown",
            label: "Shutdown",
            icon: "⏻",
            key: "s",
            argv: ["systemctl", "poweroff"]
        },
        {
            id: "reboot",
            label: "Reboot",
            icon: "󰜉",
            key: "r",
            argv: ["systemctl", "reboot"]
        },
        {
            id: "logout",
            label: "Logout",
            icon: "󰍃",
            key: "e",
            argv: ["niri", "msg", "action", "quit", "--skip-confirmation"]
        },
        {
            id: "reboot-userspace",
            label: "Reboot Userspace",
            icon: "󰑓",
            key: "h",
            argv: ["systemctl", "soft-reboot"]
        }
    ]

    onOpenedChanged: {
        if (opened)
            blurKick.restart();
        else
            blurKick.stop();
    }

    Timer {
        id: blurKick
        interval: 16
        repeat: false
        onTriggered: {
            if (!root.opened)
                return;
            BackgroundEffect.blurRegion = null;
            BackgroundEffect.blurRegion = blurRegion;
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.opened
        onActivated: root.requestClose()
    }

    Shortcut {
        sequence: "s"
        enabled: root.opened
        onActivated: root.runAction(root.actions[0].argv)
    }

    Shortcut {
        sequence: "r"
        enabled: root.opened
        onActivated: root.runAction(root.actions[1].argv)
    }

    Shortcut {
        sequence: "e"
        enabled: root.opened
        onActivated: root.runAction(root.actions[2].argv)
    }

    Shortcut {
        sequence: "h"
        enabled: root.opened
        onActivated: root.runAction(root.actions[3].argv)
    }

    MouseArea {
        anchors.fill: parent
        visible: root.opened
        onClicked: root.requestClose()
    }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -parent.height * 0.06

        implicitWidth: row.implicitWidth + root.panelPad * 2
        implicitHeight: row.implicitHeight + root.panelPad * 2
        width: implicitWidth
        height: implicitHeight
        radius: Theme.radius
        visible: root.opened
        opacity: root.opened ? 1 : 0
        clip: true
        color: Theme.panelBg
        border.width: Theme.borderWidth
        border.color: Theme.panelBorder

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }

        // Keep clicks on the panel from closing via the backdrop.
        MouseArea {
            anchors.fill: parent
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.menuPad * 1.5

            Repeater {
                model: root.actions

                MouseArea {
                    id: btn
                    required property var modelData
                    width: root.btnWidth
                    height: root.btnHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runAction(modelData.argv)

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.max(4, Theme.radius - 4)
                        color: btn.containsMouse ? Theme.selectBg : "transparent"
                        border.width: btn.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                        border.color: Theme.panelBorder

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.menuPad / 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.menuFontPointSize * 2.2
                            font.bold: true
                            scale: btn.pressed ? Theme.pressScale : (btn.containsMouse ? Theme.hoverScale : 1.0)

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Theme.animFast
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: root.btnWidth - Theme.menuPad
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: modelData.label
                            color: btn.containsMouse ? Theme.text : Theme.muted
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.menuFontPointSize
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
