pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property var names: ["crystal", "niri", "wallust"]
    readonly property string statePath: Quickshell.env("HOME") + "/.local/state/quickshell-launcher.json"
    readonly property real uiScale: 1.5

    property string name: "niri"

    function s(px) {
        return Math.round(px * root.uiScale);
    }

    property color wallustFg: "#C0DDEE"
    property color wallustBg: Qt.rgba(18 / 255, 19 / 255, 22 / 255, 0.55)
    property color wallustAccent: "#4B9DCF"
    property color wallustMuted: "#6E8A9C"
    property color wallustBorder: "#917FA2"
    property color wallustSelect: "#4D6DA4"

    readonly property var current: {
        switch (root.name) {
        case "crystal":
            return ({
                name: "crystal",
                fontFamily: "JetBrains Mono Nerd Font",
                panelBg: Qt.rgba(0, 0, 0, 0.28),
                panelBorder: Qt.rgba(1, 1, 1, 0.12),
                useGradientBorder: false,
                gradientStart: "#ffffff",
                gradientEnd: "#ffffff",
                radius: root.s(8),
                borderWidth: root.s(1),
                text: "whitesmoke",
                muted: "#6e6a86",
                accent: "whitesmoke",
                selectBg: Qt.rgba(1, 1, 1, 0.12),
                inputBg: Qt.rgba(0, 0, 0, 0.2),
                dim: Qt.rgba(0, 0, 0, 0.25),
                iconSize: root.s(22),
                width: root.s(460),
                rowHeight: root.s(40),
                fontSize: root.s(14),
                subtitleSize: root.s(11),
                searchHeight: root.s(42),
                padding: root.s(10),
                spacing: root.s(8),
            });
        case "wallust":
            return ({
                name: "wallust",
                fontFamily: "JetBrains Mono Nerd Font",
                panelBg: root.wallustBg,
                panelBorder: root.wallustBorder,
                useGradientBorder: false,
                gradientStart: root.wallustAccent,
                gradientEnd: root.wallustBorder,
                radius: root.s(10),
                borderWidth: root.s(2),
                text: root.wallustFg,
                muted: root.wallustMuted,
                accent: root.wallustAccent,
                selectBg: Qt.rgba(root.wallustSelect.r, root.wallustSelect.g, root.wallustSelect.b, 0.35),
                inputBg: Qt.rgba(0, 0, 0, 0.3),
                dim: Qt.rgba(0, 0, 0, 0.4),
                iconSize: root.s(26),
                width: root.s(480),
                rowHeight: root.s(44),
                fontSize: root.s(14),
                subtitleSize: root.s(11),
                searchHeight: root.s(42),
                padding: root.s(10),
                spacing: root.s(8),
            });
        case "niri":
        default:
            return ({
                name: "niri",
                fontFamily: "JetBrains Mono Nerd Font",
                panelBg: Qt.rgba(18 / 255, 19 / 255, 22 / 255, 0.55),
                panelBorder: "#b800e0cc",
                useGradientBorder: true,
                gradientStart: "#e5989b",
                gradientEnd: "#b800e0",
                radius: root.s(10),
                borderWidth: root.s(3),
                text: "whitesmoke",
                muted: "#9a9a9a",
                accent: "#ffb4a2",
                selectBg: Qt.rgba(184 / 255, 0, 224 / 255, 0.22),
                inputBg: Qt.rgba(0, 0, 0, 0.28),
                dim: Qt.rgba(0, 0, 0, 0.35),
                iconSize: root.s(28),
                width: root.s(500),
                rowHeight: root.s(46),
                fontSize: root.s(14),
                subtitleSize: root.s(11),
                searchHeight: root.s(42),
                padding: root.s(10),
                spacing: root.s(8),
            });
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.loadState(text())
        onLoadFailed: root.name = "niri"
    }

    FileView {
        id: wallustFile
        path: Quickshell.env("HOME") + "/.config/waybar/wallust/colors-waybar.css"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseWallust(text())
    }

    function parseCssColor(str, fallback) {
        if (!str)
            return fallback;
        const s = String(str).trim();
        const rgba = s.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)$/i);
        if (rgba) {
            return Qt.rgba(Number(rgba[1]) / 255, Number(rgba[2]) / 255, Number(rgba[3]) / 255, rgba[4] !== undefined ? Number(rgba[4]) : 1);
        }
        try {
            return Qt.color(s);
        } catch (e) {
            return fallback;
        }
    }

    function parseWallust(css) {
        if (!css)
            return;
        function colorOf(key, fallback) {
            const re = new RegExp("@define-color\\s+" + key + "\\s+([^;]+);");
            const m = css.match(re);
            return m ? m[1].trim() : fallback;
        }
        root.wallustFg = root.parseCssColor(colorOf("foreground", "#C0DDEE"), root.wallustFg);
        root.wallustBg = root.parseCssColor(colorOf("background", "rgba(18,19,22,0.55)"), root.wallustBg);
        root.wallustAccent = root.parseCssColor(colorOf("color14", "#4B9DCF"), root.wallustAccent);
        root.wallustMuted = root.parseCssColor(colorOf("color8", "#6E8A9C"), root.wallustMuted);
        root.wallustBorder = root.parseCssColor(colorOf("color13", "#917FA2"), root.wallustBorder);
        root.wallustSelect = root.parseCssColor(colorOf("color12", "#4D6DA4"), root.wallustSelect);
    }

    function loadState(text) {
        try {
            const data = JSON.parse(text || "{}");
            if (data.theme && root.names.indexOf(data.theme) >= 0)
                root.name = data.theme;
        } catch (e) {
            root.name = "niri";
        }
    }

    function saveState() {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state"]);
        stateFile.setText(JSON.stringify({
                theme: root.name
            }, null, 2) + "\n");
    }

    function setTheme(themeName) {
        if (root.names.indexOf(themeName) < 0)
            return;
        root.name = themeName;
        saveState();
    }

    function cycleTheme() {
        const idx = root.names.indexOf(root.name);
        const next = root.names[(idx + 1) % root.names.length];
        setTheme(next);
    }

    Component.onCompleted: {
        if (stateFile.loaded)
            root.loadState(stateFile.text());
        if (wallustFile.loaded)
            root.parseWallust(wallustFile.text());
    }
}
