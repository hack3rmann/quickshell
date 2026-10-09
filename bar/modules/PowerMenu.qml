import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.bar

PopupWindow {
    id: root

    property var anchorItem: null
    property bool isOpen: false

    readonly property real btnWidth: Math.round(108 * Theme.uiScale / 1.5)
    readonly property real btnHeight: Math.round(96 * Theme.uiScale / 1.5)
    readonly property real panelPad: Theme.menuPad * 1.5

    color: "transparent"
    visible: false
    grabFocus: true

    // Anchor under the power button; grow down + left (button sits on the right).
    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.adjustment: PopupAdjustment.All
    anchor.margins.bottom: -Theme.popupGap

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    property bool blurActive: false
    property int blurGen: 0
    BackgroundEffect.blurRegion: {
        if (!root.blurActive)
            return null;
        void root.blurGen;
        return blurRegion;
    }

    Region {
        id: blurRegion
        item: frame
        radius: Theme.radius
    }

    function open() {
        if (!root.anchorItem)
            return;
        closeTimer.stop();
        root.visible = true;
        root.isOpen = true;
        root.blurActive = true;
        blurKick.restart();
        reveal.show();
    }

    function close() {
        if (!root.visible && !root.isOpen)
            return;
        root.isOpen = false;
        root.blurActive = false;
        reveal.hide();
        closeTimer.restart();
    }

    function runAction(argv) {
        Quickshell.execDetached(argv);
        root.close();
    }

    Timer {
        id: closeTimer
        interval: Theme.animPopup
        repeat: false
        onTriggered: root.visible = false
    }

    Timer {
        id: blurKick
        interval: 16
        repeat: false
        onTriggered: {
            if (root.blurActive)
                root.blurGen++;
        }
    }

    readonly property var actions: [
        {
            id: "shutdown",
            label: "Shutdown",
            icon: "⏻",
            argv: ["systemctl", "poweroff"]
        },
        {
            id: "reboot",
            label: "Reboot",
            icon: "󰜉",
            argv: ["systemctl", "reboot"]
        },
        {
            id: "logout",
            label: "Logout",
            icon: "󰍃",
            argv: ["niri", "msg", "action", "quit", "--skip-confirmation"]
        },
        {
            id: "reboot-userspace",
            label: "Reboot Userspace",
            icon: "󰑓",
            argv: ["systemctl", "soft-reboot"]
        }
    ]

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }

    Shortcut {
        sequence: "s"
        enabled: root.visible
        onActivated: root.runAction(root.actions[0].argv)
    }

    Shortcut {
        sequence: "r"
        enabled: root.visible
        onActivated: root.runAction(root.actions[1].argv)
    }

    Shortcut {
        sequence: "e"
        enabled: root.visible
        onActivated: root.runAction(root.actions[2].argv)
    }

    Shortcut {
        sequence: "h"
        enabled: root.visible
        onActivated: root.runAction(root.actions[3].argv)
    }

    PopupReveal {
        id: reveal
        width: frame.implicitWidth
        height: frame.implicitHeight
        implicitWidth: width
        implicitHeight: height

        Rectangle {
            id: frame
            implicitWidth: row.implicitWidth + root.panelPad * 2
            implicitHeight: row.implicitHeight + root.panelPad * 2
            width: implicitWidth
            height: implicitHeight
            radius: Theme.radius
            color: Theme.panelBg
            border.width: Theme.borderWidth
            border.color: Theme.panelBorder
            clip: true

            Row {
                id: row
                x: root.panelPad
                y: root.panelPad
                spacing: Theme.menuPad

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
                            font.pointSize: Theme.menuFontPointSize * 2.0
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
                            font.pointSize: Theme.menuFontPointSize * 0.95
                            font.bold: true
                        }
                    }
                }
            }
        }
        }
    }
}
