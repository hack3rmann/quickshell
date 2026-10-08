import QtQuick
import Quickshell
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    cursorShape: Qt.PointingHandCursor
    property bool longFormat: false

    onClicked: root.longFormat = !root.longFormat

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    BarText {
        id: label
        anchors.centerIn: parent
        text: root.longFormat ? Qt.formatDateTime(clock.date, "HH:mm  yyyy, dd MMMM, dddd") : Qt.formatDateTime(clock.date, "HH:mm:ss")
    }
}
