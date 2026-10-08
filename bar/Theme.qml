pragma Singleton
import QtQuick

QtObject {
    readonly property real uiScale: 1.8
    readonly property real fontFactor: 0.98

    readonly property string fontFamily: "JetBrains Mono Nerd Font"
    readonly property real fontSize: 12 * uiScale * fontFactor
    readonly property real barHeight: 30 * uiScale
    readonly property real marginTop: 3 * uiScale
    readonly property real marginH: 8 * uiScale
    readonly property real spacing: 1.5 * uiScale
    readonly property real modulePadH: 6 * uiScale
    readonly property real modulePadV: 2 * uiScale
    readonly property real sepPadH: 1 * uiScale
    readonly property real cavaMinWidth: 60 * uiScale

    readonly property color text: "whitesmoke"
    readonly property color muted: "#6e6a86"
    readonly property color focused: "#d8dee9"
    readonly property color urgent: "#f53c3c"
    readonly property color critical: "#ff0000"
}
