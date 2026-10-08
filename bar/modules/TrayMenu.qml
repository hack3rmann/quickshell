import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.bar

PopupWindow {
    id: root

    property var menu: null
    property var anchorItem: null
    property bool isOpen: false

    color: "transparent"
    visible: false
    grabFocus: true

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.All

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    // Blur only behind the menu panel (same approach as the launcher).
    BackgroundEffect.blurRegion: root.visible ? blurRegion : null

    Region {
        id: blurRegion
        item: frame
        radius: Theme.radius
    }

    function open() {
        if (!root.menu || !root.anchorItem)
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
            // Re-apply after layout so the region matches the panel geometry.
            BackgroundEffect.blurRegion = null;
            BackgroundEffect.blurRegion = blurRegion;
        }
    }

    Rectangle {
        id: frame
        implicitWidth: list.menuWidth + Theme.menuPad * 2
        implicitHeight: Math.max(list.implicitHeight, Theme.menuRowHeight) + Theme.menuPad * 2
        anchors.fill: parent
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
