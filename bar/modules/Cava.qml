import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

Item {
    id: root

    readonly property int barCount: 10
    readonly property real barWidth: 2.5 * Theme.uiScale
    readonly property real barGap: 1.5 * Theme.uiScale
    readonly property real vizWidth: barCount * barWidth + (barCount - 1) * barGap

    implicitWidth: vizWidth + Theme.modulePadH
    implicitHeight: Theme.barHeight

    // 0–7 levels from cava ascii (via WaybarCava ▁▂▃▄▅▆▇█ mapping).
    property var levels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    readonly property string svg: {
        const h = Math.max(1, Theme.barHeight);
        const w = root.vizWidth;
        const bw = root.barWidth;
        const gap = root.barGap;
        const fill = Theme.text;
        const lv = root.levels;
        let rects = "";
        for (let i = 0; i < root.barCount; i++) {
            const level = Math.max(0, Math.min(7, lv[i] || 0));
            // Keep a 1px floor so idle bars stay visible.
            const bh = Math.max(1, (level + 1) / 8 * h);
            const x = i * (bw + gap);
            const y = h - bh;
            rects += `<rect x="${x}" y="${y}" width="${bw}" height="${bh}" rx="0.5" fill="${fill}"/>`;
        }
        return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${rects}</svg>`;
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
                if (next.length)
                    root.levels = next;
            }
        }
    }

    Image {
        anchors.centerIn: parent
        width: root.vizWidth
        height: Theme.barHeight
        smooth: false
        // Vector bars — no font advances / underscore gaps.
        source: "data:image/svg+xml;utf8," + encodeURIComponent(root.svg)
    }
}
