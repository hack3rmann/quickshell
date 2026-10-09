import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland
import qs.bar

PopupWindow {
    id: root

    property var anchorItem: null
    property bool isOpen: false
    property var pskTarget: null

    readonly property var wifiDevice: {
        const devices = Networking.devices ? (Networking.devices.values || []) : [];
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];
        }
        return null;
    }

    readonly property bool wifiOn: Networking.wifiEnabled && !!root.wifiDevice
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
        if (root.wifiDevice && root.wifiDevice.scannerEnabled)
            root.wifiDevice.scannerEnabled = false;
        root.pskTarget = null;
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

    readonly property var sortedNetworks: {
        const dev = root.wifiDevice;
        const raw = dev && dev.networks ? (dev.networks.values || []) : [];
        const list = [];
        for (let i = 0; i < raw.length; i++)
            list.push(raw[i]);
        list.sort(function (a, b) {
            const ac = a.connected ? 0 : (a.known ? 1 : 2);
            const bc = b.connected ? 0 : (b.known ? 1 : 2);
            if (ac !== bc)
                return ac - bc;
            const as = a.signalStrength || 0;
            const bs = b.signalStrength || 0;
            if (as !== bs)
                return bs - as;
            const an = (a.name || "").toLowerCase();
            const bn = (b.name || "").toLowerCase();
            return an < bn ? -1 : (an > bn ? 1 : 0);
        });
        return list;
    }

    function needsPsk(net) {
        if (!net || net.known || net.connected)
            return false;
        return net.security !== WifiSecurityType.Open && net.security !== WifiSecurityType.Unknown;
    }

    function networkStatus(net) {
        if (!net)
            return "";
        if (net.state === ConnectionState.Connecting || net.stateChanging)
            return "connecting…";
        if (net.state === ConnectionState.Disconnecting)
            return "disconnecting…";
        if (net.connected)
            return "connected";
        if (net.known)
            return "saved";
        if (net.security === WifiSecurityType.Open)
            return "open";
        return "secured";
    }

    function signalIcon(net) {
        const s = net ? (net.signalStrength || 0) : 0;
        if (s >= 0.8)
            return "network-wireless-signal-excellent-symbolic";
        if (s >= 0.55)
            return "network-wireless-signal-good-symbolic";
        if (s >= 0.3)
            return "network-wireless-signal-ok-symbolic";
        if (s > 0)
            return "network-wireless-signal-weak-symbolic";
        return "network-wireless-signal-none-symbolic";
    }

    function toggleNetwork(net) {
        if (!net)
            return;
        if (net.connected) {
            net.disconnect();
            root.pskTarget = null;
            return;
        }
        if (net.known || net.security === WifiSecurityType.Open) {
            root.pskTarget = null;
            net.connect();
            return;
        }
        if (root.needsPsk(net)) {
            root.pskTarget = root.pskTarget === net ? null : net;
            return;
        }
        root.pskTarget = null;
        net.connect();
    }

    function submitPsk(net, psk) {
        if (!net || !psk)
            return;
        net.connectWithPsk(psk);
        root.pskTarget = null;
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
                    text: "WiFi"
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
                    enabled: Networking.wifiHardwareEnabled
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.max(4, Theme.radius - 4)
                        color: powerBtn.containsMouse ? Theme.selectBg : "transparent"
                        border.width: powerBtn.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                        border.color: Theme.panelBorder
                        opacity: powerBtn.enabled ? 1 : 0.45
                    }

                    Text {
                        id: powerLabel
                        anchors.centerIn: parent
                        text: Networking.wifiEnabled ? "󰤨 On" : "󰖪 Off"
                        color: !powerBtn.enabled ? Theme.muted : (powerBtn.containsMouse ? Theme.text : Theme.muted)
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
                    enabled: !!(root.wifiDevice && Networking.wifiEnabled)
                    onClicked: {
                        if (root.wifiDevice)
                            root.wifiDevice.scannerEnabled = !root.wifiDevice.scannerEnabled;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.max(4, Theme.radius - 4)
                        color: scanBtn.containsMouse || (root.wifiDevice && root.wifiDevice.scannerEnabled) ? Theme.selectBg : "transparent"
                        border.width: scanBtn.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                        border.color: Theme.panelBorder
                        opacity: scanBtn.enabled ? 1 : 0.45
                    }

                    Text {
                        id: scanLabel
                        anchors.centerIn: parent
                        text: root.wifiDevice && root.wifiDevice.scannerEnabled ? "󰐰 Stop" : "󰍉 Scan"
                        color: !scanBtn.enabled ? Theme.muted : (scanBtn.containsMouse || (root.wifiDevice && root.wifiDevice.scannerEnabled) ? Theme.text : Theme.muted)
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

            // Network list
            Flickable {
                id: flick
                width: parent.width
                height: Math.min(Math.max(netCol.implicitHeight, Theme.menuRowHeight), root.listMaxHeight)
                contentHeight: netCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: netCol
                    width: flick.width
                    spacing: Theme.menuPad

                    Text {
                        visible: !root.wifiDevice
                        width: parent.width
                        text: "WiFi unavailable"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        leftPadding: Theme.menuPad / 2
                        topPadding: Theme.menuPad / 2
                        bottomPadding: Theme.menuPad / 2
                    }

                    Text {
                        visible: !!(root.wifiDevice && !Networking.wifiEnabled)
                        width: parent.width
                        text: "WiFi is off"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        leftPadding: Theme.menuPad / 2
                        topPadding: Theme.menuPad / 2
                        bottomPadding: Theme.menuPad / 2
                    }

                    Text {
                        visible: !!(root.wifiOn && root.sortedNetworks.length === 0)
                        width: parent.width
                        text: root.wifiDevice && root.wifiDevice.scannerEnabled ? "Scanning…" : "No networks"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize
                        font.bold: true
                        leftPadding: Theme.menuPad / 2
                        topPadding: Theme.menuPad / 2
                        bottomPadding: Theme.menuPad / 2
                    }

                    Repeater {
                        model: root.wifiOn ? root.sortedNetworks : []

                        Column {
                            id: rowWrap
                            required property var modelData
                            width: netCol.width
                            spacing: Theme.menuPad / 2

                            readonly property bool showPsk: root.pskTarget === modelData

                            MouseArea {
                                id: row
                                width: parent.width
                                height: Theme.menuRowHeight * 1.75
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: event => {
                                    if (event.button === Qt.RightButton) {
                                        if (modelData.known)
                                            modelData.forget();
                                        root.pskTarget = null;
                                        return;
                                    }
                                    root.toggleNetwork(modelData);
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.leftMargin: 2
                                    anchors.rightMargin: 2
                                    radius: Math.max(4, Theme.radius - 4)
                                    color: row.containsMouse || rowWrap.showPsk ? Theme.selectBg : "transparent"
                                    border.width: row.containsMouse || rowWrap.showPsk ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
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
                                        candidates: Theme.iconCandidates(root.signalIcon(modelData))
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: modelData.name || "Hidden network"
                                            elide: Text.ElideRight
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pointSize: Theme.menuFontPointSize
                                            font.bold: true
                                        }

                                        Text {
                                            width: parent.width
                                            text: {
                                                let s = root.networkStatus(modelData);
                                                const pct = Math.round((modelData.signalStrength || 0) * 100);
                                                s += " · " + pct + "%";
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
                                        visible: modelData.security !== WifiSecurityType.Open
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "󰌾"
                                        color: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.menuFontPointSize
                                        font.bold: true
                                    }

                                    Text {
                                        visible: modelData.connected || modelData.state === ConnectionState.Connecting
                                        Layout.alignment: Qt.AlignVCenter
                                        text: modelData.connected ? "󰤨" : "…"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.menuFontPointSize
                                        font.bold: true
                                    }
                                }
                            }

                            // Inline PSK for unknown secured networks
                            RowLayout {
                                visible: rowWrap.showPsk
                                width: parent.width
                                height: visible ? Theme.menuRowHeight * 1.35 : 0
                                spacing: Theme.menuPad

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Theme.menuRowHeight
                                    Layout.leftMargin: Theme.menuPad / 2
                                    radius: Math.max(4, Theme.radius - 4)
                                    color: Theme.selectBg
                                    border.width: pskField.activeFocus ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                                    border.color: Theme.panelBorder

                                    TextField {
                                        id: pskField
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.menuPad
                                        anchors.rightMargin: Theme.menuPad
                                        color: Theme.text
                                        placeholderText: "Password"
                                        placeholderTextColor: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.menuFontPointSize
                                        font.bold: true
                                        echoMode: TextInput.Password
                                        background: null
                                        selectByMouse: true
                                        onVisibleChanged: {
                                            if (visible) {
                                                text = "";
                                                forceActiveFocus();
                                            }
                                        }
                                        Keys.onReturnPressed: root.submitPsk(modelData, text)
                                        Keys.onEnterPressed: root.submitPsk(modelData, text)
                                        Keys.onEscapePressed: root.pskTarget = null
                                    }
                                }

                                MouseArea {
                                    id: joinBtn
                                    Layout.preferredWidth: joinLabel.implicitWidth + Theme.menuPad * 2
                                    Layout.preferredHeight: Theme.menuRowHeight
                                    Layout.rightMargin: Theme.menuPad / 2
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    enabled: pskField.text.length > 0
                                    onClicked: root.submitPsk(modelData, pskField.text)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Math.max(4, Theme.radius - 4)
                                        color: joinBtn.containsMouse ? Theme.selectBg : "transparent"
                                        border.width: joinBtn.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                                        border.color: Theme.panelBorder
                                        opacity: joinBtn.enabled ? 1 : 0.45
                                    }

                                    Text {
                                        id: joinLabel
                                        anchors.centerIn: parent
                                        text: "Join"
                                        color: joinBtn.enabled && joinBtn.containsMouse ? Theme.text : Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.menuFontPointSize
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Scanning indicator
            Item {
                id: scanDots
                visible: !!(root.wifiDevice && root.wifiDevice.scannerEnabled)
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
