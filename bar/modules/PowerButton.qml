import QtQuick
import Quickshell
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/Wlogout.sh"])

    BarText {
        id: label
        anchors.centerIn: parent
        text: "⏻"
    }
}
