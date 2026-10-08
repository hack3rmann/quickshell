import QtQuick
import Quickshell.Services.UPower
import qs.bar

MouseArea {
    id: root
    implicitWidth: label.implicitWidth + Theme.modulePadH * 2
    implicitHeight: Theme.barHeight
    cursorShape: Qt.PointingHandCursor

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
    }
}
