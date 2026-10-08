import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import qs.bar

PopupWindow {
    id: root

    property var anchorItem: null
    property bool isOpen: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property real panelWidth: Math.round(320 * Theme.uiScale / 1.5)
    readonly property real listMaxHeight: Math.round(280 * Theme.uiScale / 1.5)

    color: "transparent"
    visible: false
    grabFocus: true

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.All

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
        if (root.adapter && root.adapter.discovering)
            root.adapter.discovering = false;
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

    readonly property var sortedDevices: {
        const raw = Bluetooth.devices ? (Bluetooth.devices.values || []) : [];
        const list = [];
        for (let i = 0; i < raw.length; i++)
            list.push(raw[i]);
        list.sort(function (a, b) {
            const ac = a.connected ? 0 : (a.paired ? 1 : 2);
            const bc = b.connected ? 0 : (b.paired ? 1 : 2);
            if (ac !== bc)
                return ac - bc;
            const an = (a.name || a.deviceName || a.address || "").toLowerCase();
            const bn = (b.name || b.deviceName || b.address || "").toLowerCase();
            return an < bn ? -1 : (an > bn ? 1 : 0);
        });
        return list;
    }

    function deviceLabel(dev) {
        return dev.name || dev.deviceName || dev.address || "Unknown";
    }

    function deviceStatus(dev) {
        if (dev.pairing)
            return "pairing…";
        if (dev.state === BluetoothDeviceState.Connecting)
            return "connecting…";
        if (dev.state === BluetoothDeviceState.Disconnecting)
            return "disconnecting…";
        if (dev.connected)
            return "connected";
        if (dev.paired)
            return "paired";
        return "available";
    }

    function toggleDevice(dev) {
        if (!dev)
            return;
        if (dev.connected) {
            dev.disconnect();
            return;
        }
        if (!dev.paired && !dev.bonded)
            dev.pair();
        dev.connect();
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
            spacing: Theme.spacing

            // Header
            RowLayout {
                width: parent.width
                spacing: Theme.menuIconGap

                Text {
                    text: "Bluetooth"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize
                    font.bold: true
                    Layout.fillWidth: true
                }

                // Power
                MouseArea {
                    id: powerBtn
                    Layout.preferredWidth: powerLabel.implicitWidth + Theme.modulePadH
                    Layout.preferredHeight: Theme.menuRowHeight
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !!root.adapter
                    onClicked: {
                        if (root.adapter)
                            root.adapter.enabled = !root.adapter.enabled;
                    }

                    Text {
                        id: powerLabel
                        anchors.centerIn: parent
                        text: root.adapter && root.adapter.enabled ? "󰂯 On" : "󰂲 Off"
                        color: powerBtn.containsMouse ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                    }
                }

                // Scan
                MouseArea {
                    id: scanBtn
                    Layout.preferredWidth: scanLabel.implicitWidth + Theme.modulePadH
                    Layout.preferredHeight: Theme.menuRowHeight
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !!(root.adapter && root.adapter.enabled)
                    onClicked: {
                        if (root.adapter)
                            root.adapter.discovering = !root.adapter.discovering;
                    }

                    Text {
                        id: scanLabel
                        anchors.centerIn: parent
                        text: root.adapter && root.adapter.discovering ? "󰐰 Stop" : "󰍉 Scan"
                        color: !scanBtn.enabled ? Theme.muted : (scanBtn.containsMouse || (root.adapter && root.adapter.discovering) ? Theme.text : Theme.muted)
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

            // Device list
            Flickable {
                id: flick
                width: parent.width
                height: Math.min(deviceCol.implicitHeight, root.listMaxHeight)
                contentHeight: deviceCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: deviceCol
                    width: flick.width
                    spacing: 2

                    Text {
                        visible: !root.adapter || !root.adapter.enabled
                        width: parent.width
                        text: "Adapter is off"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        leftPadding: Theme.menuPad / 2
                        topPadding: Theme.spacing
                        bottomPadding: Theme.spacing
                    }

                    Text {
                        visible: !!(root.adapter && root.adapter.enabled && root.sortedDevices.length === 0)
                        width: parent.width
                        text: root.adapter && root.adapter.discovering ? "Scanning…" : "No devices"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        leftPadding: Theme.menuPad / 2
                        topPadding: Theme.spacing
                        bottomPadding: Theme.spacing
                    }

                    Repeater {
                        model: root.adapter && root.adapter.enabled ? root.sortedDevices : []

                        MouseArea {
                            id: row
                            required property var modelData
                            width: deviceCol.width
                            height: Theme.menuRowHeight
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: event => {
                                if (event.button === Qt.RightButton) {
                                    if (modelData.paired || modelData.bonded)
                                        modelData.forget();
                                    return;
                                }
                                root.toggleDevice(modelData);
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 2
                                anchors.rightMargin: 2
                                radius: Math.max(4, Theme.radius - 4)
                                color: row.containsMouse ? Theme.selectBg : "transparent"
                                border.width: row.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                                border.color: Theme.panelBorder
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.menuPad
                                anchors.rightMargin: Theme.menuPad
                                spacing: Theme.menuIconGap

                                ResolvedIcon {
                                    Layout.preferredWidth: Theme.menuRowHeight * 0.65
                                    Layout.preferredHeight: Theme.menuRowHeight * 0.65
                                    implicitSize: Theme.menuRowHeight * 0.65
                                    candidates: Theme.iconCandidates(modelData.icon || "bluetooth-symbolic")
                                    forceMono: true
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        width: parent.width
                                        text: root.deviceLabel(modelData)
                                        elide: Text.ElideRight
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.menuFontPointSize
                                        font.bold: true
                                    }

                                    Text {
                                        width: parent.width
                                        text: {
                                            let s = root.deviceStatus(modelData);
                                            if (modelData.batteryAvailable)
                                                s += " · " + Math.round(modelData.battery * 100) + "%";
                                            return s;
                                        }
                                        elide: Text.ElideRight
                                        color: modelData.connected ? Theme.text : Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.menuFontPointSize * 0.85
                                        font.bold: true
                                        opacity: 0.85
                                    }
                                }

                                Text {
                                    visible: modelData.connected || modelData.state === BluetoothDeviceState.Connecting
                                    text: modelData.connected ? "󰂱" : "…"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.menuFontPointSize
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: !!(root.adapter && root.adapter.enabled)
                width: parent.width
                text: "Right-click a paired device to forget"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.menuFontPointSize * 0.8
                font.bold: true
                opacity: 0.7
            }
        }
    }
}
