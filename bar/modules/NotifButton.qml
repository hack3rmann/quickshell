import QtQuick
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    property string screenName: ""

    readonly property bool menuOpen: Notifs.centerOpen && (!screenName || screenName === Notifs.focusedOutput)
    readonly property int count: Notifs.count
    readonly property bool dnd: Notifs.dnd

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            Notifs.toggleDnd();
            return;
        }
        Notifs.toggleCenter();
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
}
