import QtQuick
import QtQuick.Layouts
import qs.bar

RowLayout {
    id: root
    spacing: 2 * Theme.uiScale
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
            onClicked: Niri.focusWorkspace(modelData)

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
                    if (modelData.is_active || modelData.is_focused)
                        return Theme.text;
                    return Theme.muted;
                }
                font.bold: !!(modelData.is_active || modelData.is_focused)
            }
        }
    }
}
