import QtQuick
import Quickshell.Bluetooth
import qs.bar
import qs.bar.modules

Item {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight

    readonly property bool menuOpen: popup.isOpen

    HoverHandler {
        id: hover
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter && adapter.enabled
    readonly property int connectedCount: {
        const devices = Bluetooth.devices.values || [];
        let n = 0;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                n++;
        }
        return n;
    }

    BarText {
        id: label
        anchors.centerIn: parent
        scale: (hover.hovered || root.menuOpen) ? Theme.hoverScale : 1.0
        text: {
            if (!root.powered)
                return "󰂲";
            if (root.connectedCount > 0)
                return "󰂱 " + root.connectedCount;
            return "󰂯";
        }
        color: root.powered ? Theme.text : Theme.muted
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (popup.visible)
                popup.close();
            else
                popup.open();
        }
    }

    BluetoothPopup {
        id: popup
        anchorItem: hit
    }
}
