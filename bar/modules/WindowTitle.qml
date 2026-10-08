import QtQuick
import qs.bar

Item {
    id: root
    implicitWidth: Math.min(280, label.implicitWidth + Theme.modulePadH * 2)
    implicitHeight: Theme.barHeight
    clip: true

    BarText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.modulePadH
        width: parent.width - Theme.modulePadH * 2
        elide: Text.ElideRight
        text: {
            const title = Niri.focusedTitle || "";
            if (!title)
                return "";
            const app = Niri.focusedAppId || "";
            if (app)
                return app + ": " + title;
            return title;
        }
        color: Theme.text
    }
}
