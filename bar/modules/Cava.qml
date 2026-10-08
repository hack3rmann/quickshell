import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

Item {
    id: root
    implicitWidth: Math.max(Theme.cavaMinWidth, label.implicitWidth + Theme.modulePadH)
    implicitHeight: Theme.barHeight

    property string bars: ""

    Process {
        id: cavaProc
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/WaybarCava.sh"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                root.bars = data;
            }
        }
    }

    BarText {
        id: label
        anchors.centerIn: parent
        text: root.bars || "▁▁▁▁▁▁▁▁▁▁"
        color: Theme.text
    }
}
