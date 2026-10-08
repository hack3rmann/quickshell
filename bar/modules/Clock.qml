import QtQuick
import Quickshell
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    property bool longFormat: false

    onClicked: root.longFormat = !root.longFormat

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    BarText {
        id: label
        anchors.centerIn: parent
        scale: root.pressed ? Theme.pressScale : (root.containsMouse ? Theme.hoverScale : 1.0)
        text: root.longFormat ? Qt.formatDateTime(clock.date, "HH:mm  yyyy, dd MMMM, dddd") : Qt.formatDateTime(clock.date, "HH:mm:ss")
    }
}
