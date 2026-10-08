import QtQuick
import Quickshell.Networking
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
        scale: (hover.hovered || root.menuOpen) ? Theme.hoverScale : 1.0
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

    NetworkPopup {
        id: popup
        anchorItem: hit
    }
}
