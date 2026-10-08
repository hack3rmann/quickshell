import QtQuick
import qs.bar

MouseArea {
    id: root
    implicitWidth: Math.max(label.implicitWidth + Theme.modulePadH * 2, Theme.barHeight)
    implicitHeight: Theme.barHeight
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onClicked: Niri.cycleLayout()

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: Niri
        function onLayoutShortChanged() {
            label.opacity = 0.3;
            label.opacity = 1;
        }
    }

    BarText {
        id: label
        anchors.centerIn: parent
        scale: root.pressed ? Theme.pressScale : (root.containsMouse ? Theme.hoverScale : 1.0)
        text: Niri.layoutShort || "…"
    }
}
