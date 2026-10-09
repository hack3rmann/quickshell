pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: root

    property bool dnd: false
    property string focusedOutput: ""
    // Bumped when Mod+Shift+N / IPC asks the bar bell to toggle the center.
    property int centerToggleSeq: 0

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
        // Copy first — dismissing mutates the model.
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

    function toggleCenter() {
        if (focusProbe.running)
            focusProbe.running = false;
        focusProbe.running = true;
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
                root.centerToggleSeq++;
            }
        }
    }

    function timeoutMsFor(notif) {
        if (!notif)
            return 6000;
        // Respect client timeout when provided (>0). -1 / 0 often means default / never.
        const t = notif.expireTimeout;
        if (typeof t === "number" && t > 0)
            return Math.round(t * 1000);
        if (notif.urgency === NotificationUrgency.Critical)
            return 0; // no auto-expire
        if (notif.urgency === NotificationUrgency.Low)
            return 3000;
        return 6000;
    }
}
