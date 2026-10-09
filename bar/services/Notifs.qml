pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: root

    property bool dnd: false
    property bool centerOpen: false
    property string focusedOutput: ""
    // Live height of the open notification-center panel (0 when closed).
    property real centerPanelHeight: 0

    readonly property var notifications: server.trackedNotifications
    readonly property int count: {
        const vals = server.trackedNotifications ? (server.trackedNotifications.values || []) : [];
        return vals.length;
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        inlineReplySupported: false

        onNotification: notif => {
            notif.tracked = true;
            if (!root.dnd)
                root.toastRequested(notif);
        }
    }

    signal toastRequested(var notification)

    function clearAll() {
        const vals = server.trackedNotifications ? (server.trackedNotifications.values || []) : [];
        const list = [];
        for (let i = 0; i < vals.length; i++)
            list.push(vals[i]);
        for (let i = 0; i < list.length; i++) {
            try {
                list[i].dismiss();
            } catch (e) {}
        }
    }

    function toggleDnd() {
        root.dnd = !root.dnd;
    }

    function closeCenter() {
        root.centerOpen = false;
    }

    function openCenter() {
        if (focusProbe.running)
            focusProbe.running = false;
        focusProbe.running = true;
    }

    function toggleCenter() {
        if (root.centerOpen)
            root.closeCenter();
        else
            root.openCenter();
    }

    Process {
        id: focusProbe
        command: ["niri", "msg", "-j", "focused-output"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.focusedOutput = JSON.parse(text).name;
                } catch (e) {
                    console.warn("notifs focused-output parse failed:", e);
                }
                root.centerOpen = true;
            }
        }
    }

    function timeoutMsFor(notif) {
        if (!notif)
            return 6000;
        const t = notif.expireTimeout;
        if (typeof t === "number" && t > 0)
            return Math.round(t * 1000);
        if (notif.urgency === NotificationUrgency.Critical)
            return 0;
        if (notif.urgency === NotificationUrgency.Low)
            return 3000;
        return 6000;
    }
}
