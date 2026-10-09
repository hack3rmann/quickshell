import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.bar
import qs.notifications

PanelWindow {
    id: root

    // Active toast notifications (Notification objects), newest last for stacking.
    property var toasts: []

    readonly property real stackMargin: Theme.marginH
    readonly property real stackTop: Theme.marginTop + Theme.barHeight + Theme.popupGap + Theme.menuPad

    anchors {
        top: true
        right: true
    }

    margins {
        top: root.stackTop
        right: root.stackMargin
    }

    implicitWidth: Math.round(380 * Theme.uiScale / 1.5)
    implicitHeight: col.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: toasts.length > 0

    WlrLayershell.namespace: "quickshell-toasts"
    WlrLayershell.layer: WlrLayer.Overlay

    BackgroundEffect.blurRegion: root.visible && toasts.length ? blurRegion : null

    Region {
        id: blurRegion
        item: col
        // Approximate; cards have their own radius.
        radius: Theme.radius
    }

    function pushToast(notif) {
        if (!notif)
            return;
        const next = root.toasts.slice();
        // Dedupe by id if replaced.
        const id = notif.id;
        for (let i = next.length - 1; i >= 0; i--) {
            if (next[i] && next[i].id === id)
                next.splice(i, 1);
        }
        next.push(notif);
        // Cap stack size.
        while (next.length > 5)
            next.shift();
        root.toasts = next;
        blurKick.restart();
    }

    function removeToast(notif) {
        const next = [];
        for (let i = 0; i < root.toasts.length; i++) {
            if (root.toasts[i] !== notif && !(notif && root.toasts[i] && root.toasts[i].id === notif.id))
                next.push(root.toasts[i]);
        }
        root.toasts = next;
    }

    function dismissToast(notif) {
        root.removeToast(notif);
        if (notif) {
            try {
                notif.dismiss();
            } catch (e) {}
        }
    }

    Connections {
        target: Notifs
        function onToastRequested(notification) {
            root.pushToast(notification);
        }
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

    Column {
        id: col
        width: parent.width
        spacing: Theme.menuPad

        Repeater {
            model: root.toasts

            Item {
                id: wrap
                required property var modelData
                required property int index
                width: col.width
                height: card.implicitHeight

                NotificationCard {
                    id: card
                    width: parent.width
                    notification: wrap.modelData
                    compact: true
                    onDismissRequested: root.dismissToast(wrap.modelData)
                    onCloseRequested: root.removeToast(wrap.modelData)
                }

                Timer {
                    interval: Notifs.timeoutMsFor(wrap.modelData)
                    running: interval > 0 && !!wrap.modelData
                    repeat: false
                    onTriggered: {
                        root.removeToast(wrap.modelData);
                        if (wrap.modelData) {
                            try {
                                wrap.modelData.expire();
                            } catch (e) {
                                try {
                                    wrap.modelData.dismiss();
                                } catch (e2) {}
                            }
                        }
                    }
                }

                Connections {
                    target: wrap.modelData
                    function onClosed() {
                        root.removeToast(wrap.modelData);
                    }
                }
            }
        }
    }
}
