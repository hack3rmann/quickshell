import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.bar

PopupWindow {
    id: root

    property var menu: null
    property var anchorItem: null
    property bool isOpen: false
    property bool blurActive: false
    property int blurGen: 0

    color: "transparent"
    visible: false
    grabFocus: true

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.All
    anchor.margins.bottom: -Theme.popupGap

    implicitWidth: reveal.implicitWidth
    implicitHeight: reveal.implicitHeight

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
        if (!root.menu || !root.anchorItem)
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

    PopupReveal {
        id: reveal
        width: frame.implicitWidth
        height: frame.implicitHeight
        implicitWidth: width
        implicitHeight: height

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
}
