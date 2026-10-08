import QtQuick
import Quickshell
import qs.bar

PopupWindow {
    id: root

    property var menu: null
    property var anchorItem: null

    signal menuOpened
    signal menuClosed

    color: "transparent"
    visible: false
    grabFocus: true

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.All

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    function open() {
        if (!root.menu || !root.anchorItem)
            return;
        root.visible = true;
    }

    function close() {
        root.visible = false;
    }

    onVisibleChanged: {
        if (visible)
            root.menuOpened();
        else
            root.menuClosed();
    }

    Rectangle {
        id: frame
        implicitWidth: list.menuWidth + Theme.menuPad * 2
        implicitHeight: Math.max(list.implicitHeight, Theme.menuRowHeight) + Theme.menuPad * 2
        width: implicitWidth
        height: implicitHeight
        radius: Theme.radius
        color: Theme.panelBg
        border.width: Theme.borderWidth
        border.color: Theme.panelBorder
        clip: true

        TrayMenuList {
            id: list
            x: Theme.menuPad
            y: Theme.menuPad
            width: list.menuWidth
            menuHandle: root.menu
            onActivated: root.close()
        }
    }
}
