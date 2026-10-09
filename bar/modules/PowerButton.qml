import QtQuick
import Quickshell
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "powermenu", "toggle"])

    BarText {
        id: label
        anchors.centerIn: parent
        text: "⏻"
        scale: root.pressed ? Theme.pressScale : (root.containsMouse ? Theme.hoverScale : 1.0)
    }
}
