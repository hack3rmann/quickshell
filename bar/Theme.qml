pragma Singleton
import QtQuick

QtObject {
    readonly property real uiScale: 1.8
    readonly property real fontFactor: 0.98

    readonly property string fontFamily: "JetBrains Mono Nerd Font"
    readonly property real fontSize: 12 * uiScale * fontFactor
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
}
