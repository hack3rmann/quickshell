pragma Singleton
import QtQuick

Item {
    id: root

    readonly property real uiScale: 1.5

    function s(px) {
        return Math.round(px * root.uiScale);
    }

    readonly property var current: ({
            name: "crystal",
            fontFamily: "JetBrains Mono Nerd Font",
            panelBg: Qt.rgba(0, 0, 0, 0.35),
            panelBorder: Qt.rgba(1, 1, 1, 0.12),
            radius: root.s(8),
            borderWidth: root.s(1),
            text: "whitesmoke",
            muted: "#6e6a86",
            accent: "whitesmoke",
            selectBg: Qt.rgba(1, 1, 1, 0.12),
            inputBg: Qt.rgba(0, 0, 0, 0.25),
            dim: Qt.rgba(0, 0, 0, 0.2),
            iconSize: root.s(22),
            width: root.s(460),
            rowHeight: root.s(40),
            fontSize: root.s(14),
            subtitleSize: root.s(11),
            searchHeight: root.s(42),
            padding: root.s(10),
            spacing: root.s(8),
        })
}
