import QtQuick
import Quickshell
import qs.bar
import qs.bar.modules

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    readonly property bool menuOpen: popup.isOpen

    onClicked: {
        if (popup.visible)
            popup.close();
        else
            popup.open();
    }

    BarText {
        id: label
        anchors.centerIn: parent
        text: "⏻"
        scale: root.pressed ? Theme.pressScale : ((root.containsMouse || root.menuOpen) ? Theme.hoverScale : 1.0)
    }

    PowerMenu {
        id: popup
        anchorItem: root
    }
}
