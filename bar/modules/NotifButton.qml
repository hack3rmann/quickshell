import QtQuick
import Quickshell
import qs.bar
import qs.bar.modules

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    property string screenName: ""

    readonly property bool menuOpen: popup.isOpen
    readonly property int count: Notifs.count
    readonly property bool dnd: Notifs.dnd

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            Notifs.toggleDnd();
            return;
        }
        if (popup.visible)
            popup.close();
        else
            popup.open();
    }

    Connections {
        target: Notifs
        function onCenterToggleSeqChanged() {
            if (root.screenName && Notifs.focusedOutput && root.screenName !== Notifs.focusedOutput)
                return;
            if (popup.visible)
                popup.close();
            else
                popup.open();
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    BarText {
        id: label
        anchors.centerIn: parent
        scale: root.pressed ? Theme.pressScale : ((root.containsMouse || root.menuOpen) ? Theme.hoverScale : 1.0)
        color: root.dnd ? Theme.muted : Theme.text
        text: {
            let icon = "󰂚";
            if (root.dnd)
                icon = "󰂛";
            else if (root.count > 0)
                icon = "󰂞";
            return root.count > 0 ? (icon + " " + root.count) : icon;
        }
    }

    NotificationCenter {
        id: popup
        anchorItem: root
    }
}
