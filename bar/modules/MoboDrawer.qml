import QtQuick
import QtQuick.Layouts
import qs.bar

RowLayout {
    id: root
    spacing: Theme.spacing
    property bool expanded: false

    MouseArea {
        id: anchor
        Layout.preferredWidth: tempLabel.implicitWidth + Theme.modulePadH * 2
        Layout.preferredHeight: Theme.barHeight
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded

        BarText {
            id: tempLabel
            anchors.centerIn: parent
            text: SysStats.cpuTempC + "°C 󰈸"
            color: SysStats.cpuTempC >= 99 ? Theme.critical : Theme.text
        }
    }

    RowLayout {
        id: drawer
        spacing: Theme.spacing
        clip: true
        Layout.preferredWidth: root.expanded ? implicitWidth : 0
        opacity: root.expanded ? 1 : 0
        visible: Layout.preferredWidth > 0

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        BarText {
            text: SysStats.cpuUsage + "% 󰍛"
            leftPadding: Theme.modulePadH / 2
            rightPadding: Theme.modulePadH / 2
        }
        BarText {
            text: SysStats.memUsedGiB.toFixed(1) + "G 󰾆"
            leftPadding: Theme.modulePadH / 2
            rightPadding: Theme.modulePadH / 2
        }
        BarText {
            text: SysStats.diskUsedPct + "% 󰋊"
            leftPadding: Theme.modulePadH / 2
            rightPadding: Theme.modulePadH / 2
        }
    }
}
