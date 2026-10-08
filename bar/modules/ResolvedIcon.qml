import QtQuick
import Qt5Compat.GraphicalEffects
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

    // Force light recolor (menu entries). Otherwise auto for *-symbolic paths.
    property bool forceMono: false

    readonly property bool ready: img.status === Image.Ready && img.source !== ""
    readonly property bool darkMono: {
        if (root.forceMono)
            return true;
        const src = String(img.source || "");
        if (!src)
            return false;
        return src.indexOf("symbolic") >= 0 || src.indexOf("/symbolic/") >= 0;
    }

    implicitWidth: implicitSize
    implicitHeight: implicitSize
    visible: ready

    property int index: 0

    onCandidatesChanged: {
        root.index = 0;
        img.source = root.candidates.length ? root.candidates[0] : "";
    }

    // Keep the raw image in-tree for ColorOverlay sampling; hide when recoloring.
    IconImage {
        id: img
        anchors.centerIn: parent
        implicitSize: root.implicitSize
        asynchronous: true
        source: ""
        visible: root.ready && !root.darkMono
        opacity: visible ? 1 : 0

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

    // Reliable recolor for black/symbolic glyphs on crystal panels.
    ColorOverlay {
        anchors.fill: img
        source: img
        color: Theme.text
        visible: root.ready && root.darkMono
        cached: true
    }
}
