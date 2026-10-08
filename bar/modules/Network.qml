import QtQuick
import Quickshell.Networking
import qs.bar

Item {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight

    readonly property var wifiDevice: {
        const devices = Networking.devices.values || [];
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];
        }
        return null;
    }

    readonly property var wiredDevice: {
        const devices = Networking.devices.values || [];
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wired && devices[i].connected)
                return devices[i];
        }
        return null;
    }

    readonly property var activeWifi: {
        const dev = root.wifiDevice;
        if (!dev || !dev.connected)
            return null;
        const nets = dev.networks.values || [];
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected)
                return nets[i];
        }
        return null;
    }

    BarText {
        id: label
        anchors.centerIn: parent
        text: {
            if (root.wiredDevice)
                return "󰌘";
            if (!Networking.wifiEnabled || !root.wifiDevice)
                return "󰌙";
            if (!root.wifiDevice.connected)
                return "󰖪";
            const strength = root.activeWifi ? root.activeWifi.signalStrength : 0.5;
            if (strength >= 0.8)
                return "󰤨";
            if (strength >= 0.55)
                return "󰤥";
            if (strength >= 0.3)
                return "󰤢";
            return "󰤟";
        }
        color: (root.wiredDevice || (root.wifiDevice && root.wifiDevice.connected)) ? Theme.text : Theme.muted
    }
}
