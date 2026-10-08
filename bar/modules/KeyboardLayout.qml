import QtQuick
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: Niri.cycleLayout()

    BarText {
        id: label
        anchors.centerIn: parent
        text: Niri.layoutShort || "…"
    }
}
