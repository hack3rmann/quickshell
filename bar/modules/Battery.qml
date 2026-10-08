import QtQuick
import Quickshell.Services.UPower
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    hoverEnabled: true

    readonly property var device: UPower.displayDevice
    readonly property int pct: device ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: device && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged || device.state === UPowerDeviceState.PendingCharge)
    readonly property bool critical: device && !charging && pct <= 15

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    BarText {
        id: label
        anchors.centerIn: parent
        color: root.critical ? Theme.urgent : Theme.text
        scale: root.containsMouse ? Theme.hoverScale : 1.0
        text: {
            if (!root.device || !root.device.isLaptopBattery)
                return "󰚥";
            if (root.charging && root.pct >= 100)
                return "󰁹 Full";
            const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
            const idx = Math.min(10, Math.max(0, Math.round(root.pct / 10)));
            const icon = root.charging ? "󰂄" : icons[idx];
            return icon + " " + root.pct + "%";
        }
    }
}
