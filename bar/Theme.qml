pragma Singleton
import QtQuick
import Quickshell

QtObject {
    readonly property real uiScale: 1.8

    // Build candidate URLs for a tray/menu icon. Prefer real files over
    // image://icon (symbolic SVGs from Adwaita often become QS's checkerboard
    // via the icon provider, while GTK/Waybar still paint them).
    function iconCandidates(source) {
        if (!source)
            return [];
        const s = String(source);
        if (s.startsWith("file:") || s.startsWith("data:"))
            return [s];
        if (s.startsWith("/") && !s.startsWith("image:"))
            return ["file://" + s];

        let name = s;
        let themePath = "";
        if (s.startsWith("image://icon/")) {
            let rest = s.slice("image://icon/".length);
            const q = rest.indexOf("?");
            if (q >= 0) {
                name = rest.slice(0, q);
                const query = rest.slice(q + 1);
                if (query.startsWith("path="))
                    themePath = decodeURIComponent(query.slice(5));
            } else {
                name = rest;
            }
        } else if (s.startsWith("image://")) {
            // Other providers (e.g. pixmap data) — try as-is first.
            return [s];
        }

        // Prefer *-symbolic so crystal panels can recolor dark glyphs cleanly.
        // BlueZ device icons are often non-symbolic names (audio-headset, phone, …).
        const names = [];
        if (name.endsWith("-symbolic")) {
            names.push(name);
            names.push(name.slice(0, -9));
        } else {
            names.push(name + "-symbolic");
            names.push(name);
        }

        // Blueman menus / BlueZ class icons → theme names that actually exist.
        const aliases = {
            "bluetooth": "blueman",
            "bluetooth-disabled": "blueman-disabled",
            "bluetooth-disconnected": "blueman",
            "bluetooth-active": "blueman-active",
            "blueman-send": "blueman",
            "audio-headset": "audio-headphones",
            "audio-card": "audio-speakers",
            "computer": "computer",
            "phone": "phone",
            "smartphone": "phone",
            "input-gaming": "input-gaming",
            "input-keyboard": "input-keyboard",
            "input-mouse": "input-mouse",
        };
        const n0 = names.length;
        for (let i = 0; i < n0; i++) {
            const base = names[i].endsWith("-symbolic") ? names[i].slice(0, -9) : names[i];
            const mapped = aliases[base];
            if (!mapped || mapped === base)
                continue;
            if (names[i].endsWith("-symbolic"))
                names.push(mapped + "-symbolic");
            names.push(mapped);
        }

        const out = [];
        function add(url) {
            if (url && out.indexOf(url) < 0)
                out.push(url);
        }

        // Checked theme lookup (no missing-texture placeholder).
        for (let i = 0; i < names.length; i++) {
            add(Quickshell.iconPath(names[i], true));
        }

        // Direct files — Qt Image/SVG plugin can load these even when image://icon cannot.
        const dirs = [
            "Adwaita/symbolic/devices",
            "Adwaita/symbolic/status",
            "Adwaita/symbolic/actions",
            "Adwaita/symbolic/apps",
            "Adwaita/symbolic/places",
            "Adwaita/symbolic/emblems",
            "Adwaita/scalable/devices",
            "Adwaita/16x16/devices",
            "hicolor/scalable/actions",
            "hicolor/scalable/status",
            "hicolor/scalable/apps",
            "hicolor/scalable/devices",
            "hicolor/24x24/status",
            "hicolor/24x24/actions",
            "hicolor/24x24/apps",
            "hicolor/24x24/devices",
            "hicolor/22x22/status",
            "hicolor/22x22/actions",
            "hicolor/32x32/status",
            "hicolor/32x32/actions",
            "breeze/devices/22",
            "breeze/actions/22",
            "breeze/status/22",
            "breeze-dark/devices/22",
            "breeze-dark/actions/22",
            "breeze-dark/status/22",
        ];
        for (let i = 0; i < names.length; i++) {
            const n = names[i];
            for (let d = 0; d < dirs.length; d++) {
                const base = "/usr/share/icons/" + dirs[d] + "/" + n;
                add("file://" + base + ".svg");
                add("file://" + base + ".png");
            }
            if (themePath) {
                const p = themePath.replace(/\/$/, "");
                add("file://" + p + "/" + n);
                add("file://" + p + "/" + n + ".svg");
                add("file://" + p + "/" + n + ".png");
            }
        }

        return out;
    }

    function resolveIcon(source) {
        const c = iconCandidates(source);
        return c.length ? c[0] : "";
    }
    // Fractional size for even ▁/underscore advances (Waybar used ~99%; trying 97%).
    readonly property real fontFactor: 0.97

    readonly property string fontFamily: "JetBrains Mono Nerd Font"
    readonly property real fontSize: 12 * uiScale * fontFactor
    // QFont.pixelSize is int-only; pointSize accepts fractions (px→pt at 96dpi).
    readonly property real fontPointSize: fontSize * 72 / 96
    // Hug the glyph cell — no extra vertical padding that reads as top/bottom margins.
    readonly property real barHeight: Math.ceil(12 * uiScale)
    // Optical balance below the screen edge / above content.
    readonly property real marginTop: 12
    readonly property real marginBottom: 0
    readonly property real marginH: 8 * uiScale
    readonly property real spacing: 1.5 * uiScale
    readonly property real modulePadH: 6 * uiScale
    readonly property real modulePadV: 0
    readonly property real sepPadH: 1 * uiScale
    readonly property real cavaMinWidth: 60 * uiScale

    readonly property color text: "whitesmoke"
    readonly property color muted: "#6e6a86"
    readonly property color focused: "#d8dee9"
    readonly property color urgent: "#f53c3c"
    readonly property color critical: "#ff0000"

    // Crystal Clear panels (match launcher)
    readonly property color panelBg: Qt.rgba(0, 0, 0, 0.4)
    readonly property color panelBorder: Qt.rgba(1, 1, 1, 0.9)
    readonly property color selectBg: Qt.rgba(1, 1, 1, 0.12)
    readonly property real radius: Math.round(8 * uiScale / 1.5)
    readonly property real borderWidth: Math.max(1, Math.round(1.5 * uiScale / 1.5))
    readonly property real menuPad: Math.round(8 * uiScale / 1.5)
    readonly property real menuIconGap: Math.round(10 * uiScale / 1.5)
    readonly property real menuRowHeight: Math.round(28 * uiScale / 1.5)
    readonly property real menuFontPointSize: fontPointSize
    // Gap below the bar anchor before popups (negative bottom margin expands the rect).
    readonly property int popupGap: Math.round(6 * uiScale / 1.5)

    // Motion
    readonly property int animFast: 140
    readonly property int animNormal: 260
    readonly property int animSlow: 420
    readonly property int animDrawer: 500
    readonly property int animCavaBar: 55
    readonly property real hoverScale: 1.12
    readonly property real pressScale: 0.92
}
