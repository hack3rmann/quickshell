import QtQuick
import Quickshell.Bluetooth
import qs.bar

Item {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight

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
        text: {
            if (!root.powered)
                return "󰂲";
            if (root.connectedCount > 0)
                return "󰂱 " + root.connectedCount;
            return "󰂯";
        }
        color: root.powered ? Theme.text : Theme.muted
    }
}
