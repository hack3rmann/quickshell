import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

Item {
    id: root

    readonly property int barCount: 10
    readonly property real barWidth: 2.5 * Theme.uiScale
    readonly property real barGap: 1.5 * Theme.uiScale

    implicitWidth: row.implicitWidth + Theme.modulePadH
    implicitHeight: Theme.barHeight

    // 0–7 levels from cava (via WaybarCava ▁▂▃▄▅▆▇█ mapping).
    property var levels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

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
                if (next.length === root.barCount)
                    root.levels = next;
            }
        }
    }

    // Vector rects updated in place — no Image/SVG reload flicker.
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
                }
            }
        }
    }
}
