import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.bar

Item {
    id: root
    property real maxWidth: Number.POSITIVE_INFINITY

    readonly property bool hasTitle: !!(Niri.focusedTitle || Niri.focusedAppId)
    readonly property bool hasTray: SystemTray.items.values.length > 0
    readonly property bool revealTray: (hover.hovered || menuOpen) && hasTray
    property int menuOpen: 0

    readonly property string titleText: {
        const title = Niri.focusedTitle || "";
        if (!title)
            return "";
        const app = Niri.focusedAppId || "";
        if (app)
            return app + ": " + title;
        return title;
    }

    readonly property real titleNatural: label.implicitWidth + Theme.modulePadH * 2
    readonly property real trayNatural: trayRow.implicitWidth + (trayRow.implicitWidth > 0 ? Theme.spacing : 0)
    readonly property real combinedNatural: (revealTray ? trayNatural : 0) + (hasTitle ? titleNatural : 0)

    implicitWidth: {
        if (!Number.isFinite(root.maxWidth))
            return root.combinedNatural;
        return Math.min(root.maxWidth, Math.max(root.combinedNatural, hasTitle || hasTray ? Theme.barHeight : 0));
    }
    implicitHeight: Theme.barHeight
    clip: true
    opacity: (hasTitle || hasTray) ? 1 : 0
    visible: opacity > 0.01

    HoverHandler {
        id: hover
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    onTitleTextChanged: {
        if (!root.hasTitle)
            return;
        label.opacity = 0.25;
        label.opacity = 1;
    }

    Row {
        id: row
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight
        spacing: 0

        // Tray slides open left → right beside the title.
        Item {
            id: traySlot
            height: Theme.barHeight
            width: root.revealTray ? root.trayNatural : 0
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animNormal
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                id: trayRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing
                height: Theme.barHeight

                Repeater {
                    model: SystemTray.items

                    MouseArea {
                        id: trayItem
                        required property var modelData
                        width: Theme.barHeight
                        height: Theme.barHeight
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                        IconImage {
                            anchors.centerIn: parent
                            source: trayItem.modelData.icon
                            implicitSize: Math.round(Theme.barHeight * 0.85)
                            asynchronous: true
                            opacity: trayItem.containsMouse ? 1 : 0.85
                            scale: trayItem.pressed ? Theme.pressScale : (trayItem.containsMouse ? Theme.hoverScale : 1.0)

                            Behavior on opacity {
                                NumberAnimation {
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

                        onClicked: event => {
                            if (event.button === Qt.MiddleButton) {
                                modelData.secondaryActivate();
                                return;
                            }
                            if (event.button === Qt.LeftButton && !modelData.onlyMenu) {
                                modelData.activate();
                                return;
                            }
                            if (modelData.hasMenu)
                                trayMenu.open();
                        }

                        onWheel: event => {
                            modelData.scroll(event.angleDelta.y, false);
                        }

                        QsMenuAnchor {
                            id: trayMenu
                            menu: trayItem.modelData.menu
                            anchor.item: trayItem
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                            onOpened: root.menuOpen++
                            onClosed: root.menuOpen = Math.max(0, root.menuOpen - 1)
                        }
                    }
                }
            }
        }

        Item {
            id: titleSlot
            height: Theme.barHeight
            width: {
                if (!root.hasTitle)
                    return 0;
                const remaining = Number.isFinite(root.maxWidth)
                    ? Math.max(0, root.maxWidth - traySlot.width)
                    : root.titleNatural;
                return Math.min(root.titleNatural, remaining);
            }
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animNormal
                    easing.type: Easing.OutCubic
                }
            }

            BarText {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.modulePadH
                width: Math.max(0, parent.width - Theme.modulePadH * 2)
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                text: root.titleText
                color: Theme.text
            }
        }
    }
}
