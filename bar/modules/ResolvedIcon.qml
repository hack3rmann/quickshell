import QtQuick
import Quickshell.Widgets
import qs.bar

// Tries icon candidates until one loads. Avoids Quickshell's pink/black
// missing-texture pixmap (image://icon SVG theme lookups often fail while
// GTK/Waybar still show the same symbolic icons).
Item {
    id: root

    property var candidates: []
    property real implicitSize: 16
    property alias asynchronous: img.asynchronous
    property alias mipmap: img.mipmap
    property alias status: img.status

    readonly property bool ready: img.status === Image.Ready && img.source !== ""

    implicitWidth: implicitSize
    implicitHeight: implicitSize
    visible: ready

    property int index: 0

    onCandidatesChanged: {
        root.index = 0;
        img.source = root.candidates.length ? root.candidates[0] : "";
    }

    IconImage {
        id: img
        anchors.centerIn: parent
        implicitSize: root.implicitSize
        asynchronous: true
        source: ""
        visible: root.ready

        onStatusChanged: {
            if (status === Image.Error || status === Image.Null) {
                if (root.index + 1 < root.candidates.length) {
                    root.index++;
                    source = root.candidates[root.index];
                } else {
                    source = "";
                }
            }
        }
    }
}
