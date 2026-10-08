pragma Singleton
import QtQuick
import Quickshell

QtObject {
    readonly property real uiScale: 1.8

    // Resolve tray/menu icons without Quickshell's pink/black missing-texture pixmap.
    // DBus menus often hand us image://icon/<name>; iconPath(..., true) returns "" if absent.
    function resolveIcon(source) {
        if (!source)
            return "";
        const s = String(source);
        if (s.startsWith("image://icon/")) {
            let rest = s.slice("image://icon/".length);
            let name = rest;
            let path = "";
            const q = rest.indexOf("?");
            if (q >= 0) {
                name = rest.slice(0, q);
                const query = rest.slice(q + 1);
                if (query.startsWith("path="))
                    path = decodeURIComponent(query.slice(5));
                else if (query.startsWith("fallback="))
                    return Quickshell.iconPath(name, query.slice(9));
            }
            const themed = Quickshell.iconPath(name, true);
            if (themed)
                return themed;
            if (path) {
                const base = name.includes("/") ? name.slice(name.lastIndexOf("/") + 1) : name;
                return "file://" + path.replace(/\/$/, "") + "/" + base;
            }
            return "";
        }
        if (s.startsWith("image://") || s.startsWith("file:") || s.startsWith("data:"))
            return s;
        if (s.startsWith("/"))
            return "file://" + s;
        return Quickshell.iconPath(s, true) || "";
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
    readonly property real menuRowHeight: Math.round(28 * uiScale / 1.5)
    readonly property real menuFontPointSize: fontPointSize

    // Motion
    readonly property int animFast: 140
    readonly property int animNormal: 260
    readonly property int animSlow: 420
    readonly property int animDrawer: 500
    readonly property int animCavaBar: 55
    readonly property real hoverScale: 1.12
    readonly property real pressScale: 0.92
}
