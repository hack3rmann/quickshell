import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.bar
import qs.notifications

PanelWindow {
    id: root

    readonly property real toastWidth: Math.round(380 * Theme.uiScale / 1.5)
    readonly property real baseTop: Theme.marginTop + Theme.barHeight + Theme.popupGap + Theme.menuPad
    readonly property real stackTop: root.baseTop + (Notifs.centerOpen && Notifs.centerPanelHeight > 0 ? Notifs.centerPanelHeight + Theme.menuPad : 0)

    anchors {
        left: true
        right: true
        top: true
    }

    margins {
        top: root.stackTop
    }

    Behavior on margins.top {
        NumberAnimation {
            duration: Theme.animPopup
            easing.type: Easing.OutCubic
        }
    }

    implicitHeight: Math.max(col.implicitHeight, 1)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: toastModel.count > 0

    // Binding-only blur — never assign BackgroundEffect.blurRegion in JS.
    property int blurGen: 0
    BackgroundEffect.blurRegion: {
        if (toastModel.count <= 0)
            return null;
        void root.blurGen;
        return blurRegion;
    }

    WlrLayershell.namespace: "quickshell-toasts"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: toastModel.count > 0 ? toastMask : emptyMask

    Region {
        id: emptyMask
    }

    Region {
        id: toastMask
        item: col
    }

    Region {
        id: blurRegion
        item: col
        radius: Theme.radius
    }

    ListModel {
        id: toastModel
    }

    function indexOfNotif(notif) {
        if (!notif)
            return -1;
        for (let i = 0; i < toastModel.count; i++) {
            const n = toastModel.get(i).notification;
            if (n === notif || (n && notif && n.id === notif.id))
                return i;
        }
        return -1;
    }

    function pushToast(notif) {
        if (!notif)
            return;
        const existing = root.indexOfNotif(notif);
        if (existing >= 0)
            toastModel.remove(existing);
        toastModel.append({
            notification: notif
        });
        while (toastModel.count > 5)
            toastModel.remove(0);
        root.blurGen++;
    }

    function removeAt(index) {
        if (index < 0 || index >= toastModel.count)
            return;
        toastModel.remove(index);
        root.blurGen++;
    }

    function removeToast(notif) {
        root.removeAt(root.indexOfNotif(notif));
    }

    function dismissToast(notif) {
        const idx = root.indexOfNotif(notif);
        if (idx >= 0)
            root.removeAt(idx);
        if (notif) {
            try {
                notif.dismiss();
            } catch (e) {}
        }
    }

    // Toast timeout only hides the popup. The notification stays tracked in the
    // center until the user dismisses it (GNOME/swaync-style persistence).
    function hideToast(notif) {
        root.removeToast(notif);
    }

    Connections {
        target: Notifs
        function onToastRequested(notification) {
            root.pushToast(notification);
        }
    }

    Column {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.toastWidth
        spacing: Theme.menuPad

        // ListModel keeps sibling delegates alive — only the changed row animates.
        add: Transition {
            SequentialAnimation {
                PropertyAction {
                    property: "opacity"
                    value: 0
                }
                PropertyAction {
                    property: "scale"
                    value: Theme.toastScaleFrom
                }
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: Theme.animToast
                        easing.type: Easing.OutBack
                    }
                    NumberAnimation {
                        property: "scale"
                        to: 1
                        duration: Theme.animToast
                        easing.type: Easing.OutBack
                    }
                }
            }
        }

        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: Theme.animToast
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: toastModel

            NotificationCard {
                id: card
                required property var model
                required property int index
                width: col.width
                notification: model.notification
                compact: true
                transformOrigin: Item.Top

                onDismissRequested: root.dismissToast(model.notification)
                onCloseRequested: root.removeToast(model.notification)

                Timer {
                    interval: Notifs.timeoutMsFor(card.notification)
                    running: interval > 0 && !!card.notification
                    repeat: false
                    onTriggered: root.hideToast(card.notification)
                }

                Connections {
                    target: card.notification
                    function onClosed() {
                        root.removeToast(card.notification);
                    }
                }
            }
        }
    }
}
