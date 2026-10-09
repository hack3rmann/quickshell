import QtQuick
import Quickshell.Services.UPower
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH
    implicitHeight: Theme.barHeight
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    readonly property bool performance: PowerProfiles.profile === PowerProfile.Performance

    onClicked: {
        if (!PowerProfiles.hasPerformanceProfile)
            return;
        PowerProfiles.profile = root.performance ? PowerProfile.Balanced : PowerProfile.Performance;
    }

    BarText {
        id: label
        anchors.centerIn: parent
        text: root.performance ? "󰓅" : "󰾅"
        color: root.performance ? Theme.text : Theme.muted
        scale: root.pressed ? Theme.pressScale : (root.containsMouse ? Theme.hoverScale : 1.0)
    }
}
