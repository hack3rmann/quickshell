import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    property string iconText: "󰂚"
    property int count: 0
    property bool dnd: false

    onClicked: event => {
        if (event.button === Qt.RightButton)
            Quickshell.execDetached(["swaync-client", "-d", "-sw"]);
        else
            Quickshell.execDetached(["bash", "-c", "sleep 0.1 && swaync-client -t -sw"]);
        poll.running = true;
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    Process {
        id: poll
        command: ["swaync-client", "-swb"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.count = data.count || 0;
                    root.dnd = !!data.dnd;
                    const alt = data.alt || "";
                    if (alt === "dnd-none" || alt === "dnd-notification" || root.dnd)
                        root.iconText = "󰂛";
                    else if (root.count > 0)
                        root.iconText = "󰂞";
                    else
                        root.iconText = "󰂚";
                } catch (e) {}
            }
        }
    }

    BarText {
        id: label
        anchors.centerIn: parent
        scale: root.pressed ? Theme.pressScale : (root.containsMouse ? Theme.hoverScale : 1.0)
        color: root.dnd ? Theme.muted : Theme.text
        text: root.count > 0 ? (root.iconText + " " + root.count) : root.iconText
    }
}
