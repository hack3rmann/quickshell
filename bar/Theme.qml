pragma Singleton
import QtQuick

QtObject {
    readonly property string fontFamily: "JetBrains Mono Nerd Font"
    readonly property int fontSize: 12
    readonly property int barHeight: 30
    readonly property int marginTop: 3
    readonly property int marginH: 8
    readonly property int spacing: 3
    readonly property int modulePadH: 6
    readonly property int modulePadV: 2

    readonly property color text: "whitesmoke"
    readonly property color muted: "#6e6a86"
    readonly property color focused: "#d8dee9"
    readonly property color urgent: "#f53c3c"
    readonly property color critical: "#ff0000"
}
