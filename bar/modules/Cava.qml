import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

Item {
    id: root

    readonly property int barCount: 10
    readonly property real barWidth: 2.5 * Theme.uiScale
    readonly property real barGap: 1.5 * Theme.uiScale
    readonly property real fullWidth: row.implicitWidth + Theme.modulePadH

    property bool shown: false
    // Animated reveal so show/hide doesn't pop.
    property real reveal: shown ? 1 : 0

    Behavior on reveal {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: fullWidth * reveal
    implicitHeight: Theme.barHeight
    opacity: reveal
    clip: true
    visible: reveal > 0.01

    // 0–7 levels from cava (via WaybarCava ▁▂▃▄▅▆▇█ mapping).
    property var levels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    function levelsSilent(lv) {
        for (let i = 0; i < lv.length; i++) {
            if (lv[i] > 0)
                return false;
        }
        return true;
    }

    Process {
        id: cavaProc
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/WaybarCava.sh"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const chars = "▁▂▃▄▅▆▇█";
                const next = [];
                for (let i = 0; i < data.length; i++) {
                    const idx = chars.indexOf(data[i]);
                    if (idx >= 0)
                        next.push(idx);
                }
                if (next.length !== root.barCount)
                    return;
                root.levels = next;
                if (!root.levelsSilent(next)) {
                    hideTimer.stop();
                    root.shown = true;
                } else if (root.shown && !hideTimer.running) {
                    hideTimer.start();
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.shown = false
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.barGap
        height: Theme.barHeight

        Repeater {
            model: root.barCount

            Item {
                required property int index
                width: root.barWidth
                height: Theme.barHeight

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: {
                        const level = Math.max(0, Math.min(7, root.levels[index] || 0));
                        return Math.max(1, (level + 1) / 8 * Theme.barHeight);
                    }
                    color: Theme.text
                    radius: 0.5

                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.animCavaBar
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
