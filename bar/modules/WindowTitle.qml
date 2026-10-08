import QtQuick
import qs.bar

Item {
    id: root
    property real maxWidth: Number.POSITIVE_INFINITY

    readonly property real contentWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitWidth: Number.isFinite(root.maxWidth) ? Math.min(root.maxWidth, root.contentWidth) : root.contentWidth
    implicitHeight: Theme.barHeight
    clip: true
    opacity: hasTitle ? 1 : 0
    visible: opacity > 0.01

    readonly property bool hasTitle: !!(Niri.focusedTitle || Niri.focusedAppId)
    readonly property string titleText: {
        const title = Niri.focusedTitle || "";
        if (!title)
            return "";
        const app = Niri.focusedAppId || "";
        if (app)
            return app + ": " + title;
        return title;
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    onTitleTextChanged: {
        if (!root.hasTitle)
            return;
        label.opacity = 0.25;
        label.opacity = 1;
    }

    BarText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.modulePadH
        width: Math.max(0, parent.width - Theme.modulePadH * 2)
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
        text: root.titleText
        color: Theme.text
    }
}
