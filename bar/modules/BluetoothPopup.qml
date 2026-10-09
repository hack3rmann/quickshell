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
    anchor.margins.bottom: -Theme.popupGap

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
            spacing: Theme.menuPad * 1.5

            // Header
            RowLayout {
                width: parent.width
                height: Theme.menuRowHeight
                spacing: Theme.menuPad * 1.25

                Text {
                    text: "Bluetooth"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize
                    font.bold: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Theme.menuPad
                    elide: Text.ElideRight
                }

                // Power
                MouseArea {
                    id: powerBtn
                    Layout.preferredWidth: powerLabel.implicitWidth + Theme.menuPad * 2.5
                    Layout.preferredHeight: Theme.menuRowHeight
                    Layout.alignment: Qt.AlignVCenter
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !!root.adapter
                    onClicked: {
                        if (root.adapter)
                            root.adapter.enabled = !root.adapter.enabled;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.max(4, Theme.radius - 4)
                        color: powerBtn.containsMouse ? Theme.selectBg : "transparent"
                        border.width: powerBtn.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                        border.color: Theme.panelBorder
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
                    Layout.preferredWidth: scanLabel.implicitWidth + Theme.menuPad * 2.5
                    Layout.preferredHeight: Theme.menuRowHeight
                    Layout.alignment: Qt.AlignVCenter
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !!(root.adapter && root.adapter.enabled)
                    onClicked: {
                        if (root.adapter)
                            root.adapter.discovering = !root.adapter.discovering;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.max(4, Theme.radius - 4)
                        color: scanBtn.containsMouse || (root.adapter && root.adapter.discovering) ? Theme.selectBg : "transparent"
                        border.width: scanBtn.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                        border.color: Theme.panelBorder
                        opacity: scanBtn.enabled ? 1 : 0.45
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
                height: Math.min(Math.max(deviceCol.implicitHeight, Theme.menuRowHeight), root.listMaxHeight)
                contentHeight: deviceCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: deviceCol
                    width: flick.width
                    spacing: Theme.menuPad

                    Text {
                        visible: !root.adapter || !root.adapter.enabled
                        width: parent.width
                        height: visible ? implicitHeight + Theme.menuPad : 0
                        text: "Adapter is off"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        leftPadding: Theme.menuPad / 2
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        visible: !!(root.adapter && root.adapter.enabled && root.sortedDevices.length === 0)
                        width: parent.width
                        height: visible ? implicitHeight + Theme.menuPad : 0
                        text: root.adapter && root.adapter.discovering ? "Scanning…" : "No devices"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        leftPadding: Theme.menuPad / 2
                        verticalAlignment: Text.AlignVCenter
                    }

                    Repeater {
                        model: root.adapter && root.adapter.enabled ? root.sortedDevices : []

                        MouseArea {
                            id: row
                            required property var modelData
                            width: deviceCol.width
                            height: Theme.menuRowHeight * 1.75
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
                                anchors.topMargin: Theme.menuPad / 3
                                anchors.bottomMargin: Theme.menuPad / 3
                                spacing: Theme.menuIconGap

                                ResolvedIcon {
                                    Layout.preferredWidth: Theme.menuRowHeight * 0.7
                                    Layout.preferredHeight: Theme.menuRowHeight * 0.7
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitSize: Theme.menuRowHeight * 0.7
                                    // Prefer symbolic via Theme.iconCandidates; auto-recolor those only.
                                    // forceMono turns full-color BlueZ icons (breeze audio-headset) into white squares.
                                    candidates: Theme.iconCandidates(modelData.icon || "bluetooth")
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

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
                                    Layout.alignment: Qt.AlignVCenter
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

            // Scanning indicator
            Item {
                id: scanDots
                visible: !!(root.adapter && root.adapter.discovering)
                width: parent.width
                height: visible ? Theme.menuRowHeight * 0.7 : 0

                property int phase: 0

                Timer {
                    running: scanDots.visible
                    interval: 320
                    repeat: true
                    onTriggered: scanDots.phase = (scanDots.phase + 1) % 3
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Math.max(4, Theme.menuPad / 2)

                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            width: Math.max(4, Math.round(Theme.menuPad * 0.45))
                            height: width
                            radius: width / 2
                            color: Theme.text
                            opacity: scanDots.phase === index ? 1.0 : 0.25

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Theme.animFast
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
