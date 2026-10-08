import QtQuick
import QtQuick.Layouts
import qs.bar

RowLayout {
    id: root
    spacing: 1 * Theme.uiScale
    required property string outputName

    readonly property var roman: ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
    readonly property var spaces: Niri.workspacesForOutput(root.outputName)

    Repeater {
        model: root.spaces

        MouseArea {
            id: ws
            required property var modelData
            Layout.preferredWidth: label.implicitWidth + 10 * Theme.uiScale
            Layout.preferredHeight: Theme.barHeight
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Niri.focusWorkspace(modelData)

            readonly property bool active: !!(modelData.is_active || modelData.is_focused)

            BarText {
                id: label
                anchors.centerIn: parent
                text: {
                    const idx = modelData.idx || 0;
                    return idx > 0 && idx < root.roman.length ? root.roman[idx] : String(idx);
                }
                color: {
                    if (modelData.is_urgent)
                        return Theme.urgent;
                    if (ws.active)
                        return Theme.text;
                    return Theme.muted;
                }
                font.bold: ws.active
                scale: ws.pressed ? Theme.pressScale : (ws.containsMouse ? Theme.hoverScale : (ws.active ? 1.06 : 1.0))
            }
        }
    }
}
