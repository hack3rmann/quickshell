import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.bar
import qs.notifications

PopupWindow {
    id: root

    property var anchorItem: null
    property bool isOpen: false

    readonly property real panelWidth: Math.round(380 * Theme.uiScale / 1.5)
    readonly property real listMaxHeight: Math.round(420 * Theme.uiScale / 1.5)

    color: "transparent"
    visible: false
    grabFocus: true

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.All
    anchor.margins.bottom: -Theme.popupGap

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    BackgroundEffect.blurRegion: root.visible ? blurRegion : null

    Region {
        id: blurRegion
        item: frame
        radius: Theme.radius
    }

    function open() {
        if (!root.anchorItem)
            return;
        root.visible = true;
    }

    function close() {
        root.visible = false;
    }

    onVisibleChanged: {
        root.isOpen = visible;
        if (visible)
            blurKick.restart();
        else
            blurKick.stop();
    }

    Timer {
        id: blurKick
        interval: 16
        repeat: false
        onTriggered: {
            if (!root.visible)
                return;
            BackgroundEffect.blurRegion = null;
            BackgroundEffect.blurRegion = blurRegion;
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }

    readonly property var notifList: {
        const raw = Notifs.notifications ? (Notifs.notifications.values || []) : [];
        const list = [];
        for (let i = 0; i < raw.length; i++)
            list.push(raw[i]);
        // Newest first.
        list.reverse();
        return list;
    }

    Rectangle {
        id: frame
        implicitWidth: root.panelWidth
        implicitHeight: contentCol.implicitHeight + Theme.menuPad * 2
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panelBg
        border.width: Theme.borderWidth
        border.color: Theme.panelBorder
        clip: true

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
                    }

                    Text {
                        id: dndLabel
                        anchors.centerIn: parent
                        text: Notifs.dnd ? "󰂛 DND" : "󰂚 DND"
                        color: Notifs.dnd || dndBtn.containsMouse ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
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
                    }

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear"
                        color: clearBtn.enabled && clearBtn.containsMouse ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
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
                height: Math.min(Math.max(listCol.implicitHeight, Theme.menuRowHeight), root.listMaxHeight)
                contentHeight: listCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: listCol
                    width: flick.width
                    spacing: Theme.menuPad

                    Text {
                        visible: root.notifList.length === 0
                        width: parent.width
                        text: "No notifications"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        leftPadding: Theme.menuPad / 2
                        topPadding: Theme.menuPad / 2
                        bottomPadding: Theme.menuPad / 2
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
