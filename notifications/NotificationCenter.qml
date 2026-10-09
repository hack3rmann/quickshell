import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.bar
import qs.notifications

PanelWindow {
    id: root

    property bool opened: false

    signal closeRequested

    readonly property real panelWidth: Math.round(420 * Theme.uiScale / 1.5)
    readonly property real listMaxHeight: Math.round(420 * Theme.uiScale / 1.5)
    readonly property real stackTop: Theme.marginTop + Theme.barHeight + Theme.popupGap + Theme.menuPad

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

    WlrLayershell.namespace: "quickshell-notif-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Blur/mask only while open. Binding-only — JS assign breaks blur after first close.
    property int blurGen: 0
    BackgroundEffect.blurRegion: {
        if (!root.opened)
            return null;
        void root.blurGen;
        return blurRegion;
    }
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

    onOpenedChanged: {
        if (opened) {
            blurKick.restart();
            syncCenterHeight();
        } else {
            Notifs.centerPanelHeight = 0;
        }
    }

    function syncCenterHeight() {
        Notifs.centerPanelHeight = panel.height;
    }

    Connections {
        target: panel
        function onHeightChanged() {
            if (root.opened)
                root.syncCenterHeight();
        }
    }

    Timer {
        id: blurKick
        interval: 16
        repeat: false
        onTriggered: {
            if (root.opened)
                root.blurGen++;
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.opened
        onActivated: root.requestClose()
    }

    readonly property var notifList: {
        const raw = Notifs.notifications ? (Notifs.notifications.values || []) : [];
        const list = [];
        for (let i = 0; i < raw.length; i++)
            list.push(raw[i]);
        list.reverse();
        return list;
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.opened
        visible: root.opened
        opacity: root.opened ? 1 : 0
        onClicked: root.requestClose()

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.stackTop + (root.opened ? 0 : -20)

        implicitWidth: root.panelWidth
        implicitHeight: contentCol.implicitHeight + Theme.menuPad * 2
        width: implicitWidth
        height: implicitHeight
        radius: Theme.radius
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.96
        transformOrigin: Item.Top
        clip: true
        color: Theme.panelBg
        border.width: Theme.borderWidth
        border.color: Theme.panelBorder
        // Keep hittable only while open.
        enabled: root.opened

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }
        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitHeight {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: contentCol
            x: Theme.menuPad
            y: Theme.menuPad
            width: root.panelWidth - Theme.menuPad * 2
            spacing: Theme.menuPad * 1.25

            RowLayout {
                width: parent.width
                height: Theme.menuRowHeight
                spacing: Theme.menuPad

                Text {
                    text: "Notifications"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize
                    font.bold: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Theme.menuPad / 2
                }

                MouseArea {
                    id: dndBtn
                    Layout.preferredWidth: dndLabel.implicitWidth + Theme.menuPad * 2.5
                    Layout.preferredHeight: Theme.menuRowHeight
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Notifs.toggleDnd()

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.max(4, Theme.radius - 4)
                        color: dndBtn.containsMouse || Notifs.dnd ? Theme.selectBg : "transparent"
                        border.width: dndBtn.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                        border.color: Theme.panelBorder

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on border.width {
                            NumberAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Text {
                        id: dndLabel
                        anchors.centerIn: parent
                        text: Notifs.dnd ? "󰂛 DND" : "󰂚 DND"
                        color: Notifs.dnd || dndBtn.containsMouse ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        scale: dndBtn.pressed ? Theme.pressScale : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                MouseArea {
                    id: clearBtn
                    Layout.preferredWidth: clearLabel.implicitWidth + Theme.menuPad * 2.5
                    Layout.preferredHeight: Theme.menuRowHeight
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: root.notifList.length > 0
                    onClicked: Notifs.clearAll()

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.max(4, Theme.radius - 4)
                        color: clearBtn.containsMouse ? Theme.selectBg : "transparent"
                        border.width: clearBtn.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                        border.color: Theme.panelBorder
                        opacity: clearBtn.enabled ? 1 : 0.45

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on border.width {
                            NumberAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear"
                        color: clearBtn.enabled && clearBtn.containsMouse ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        scale: clearBtn.pressed ? Theme.pressScale : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.25)
            }

            Flickable {
                id: flick
                width: parent.width
                height: Math.min(listCol.implicitHeight, root.listMaxHeight)
                contentHeight: listCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.animPopup
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    id: listCol
                    width: flick.width
                    spacing: Theme.menuPad

                    Text {
                        visible: root.notifList.length === 0
                        width: parent.width
                        opacity: visible ? 1 : 0
                        text: "No notifications"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        leftPadding: Theme.menuPad / 2
                        topPadding: Theme.menuPad / 2
                        bottomPadding: Theme.menuPad / 2

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Repeater {
                        model: root.notifList

                        NotificationCard {
                            required property var modelData
                            width: listCol.width
                            notification: modelData
                            compact: false
                            onDismissRequested: {
                                try {
                                    modelData.dismiss();
                                } catch (e) {}
                            }
                            onCloseRequested: {
                                try {
                                    modelData.dismiss();
                                } catch (e) {}
                            }
                        }
                    }
                }
            }
        }
    }
}
