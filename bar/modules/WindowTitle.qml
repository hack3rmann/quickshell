import QtQuick
import qs.bar

Item {
    id: root
    // Cap at the center cluster; otherwise size to the full title.
    property real maxWidth: Number.POSITIVE_INFINITY

    readonly property real contentWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitWidth: Number.isFinite(root.maxWidth) ? Math.min(root.maxWidth, root.contentWidth) : root.contentWidth
    implicitHeight: Theme.barHeight
    clip: true
    visible: !!(Niri.focusedTitle || Niri.focusedAppId)

    BarText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.modulePadH
        width: Math.max(0, parent.width - Theme.modulePadH * 2)
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
