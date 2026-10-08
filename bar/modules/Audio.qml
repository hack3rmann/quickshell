import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.bar

RowLayout {
    id: root
    spacing: Theme.spacing

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    MouseArea {
        id: sinkArea
        Layout.preferredWidth: sinkLabel.implicitWidth + Theme.modulePadH
        Layout.preferredHeight: Theme.barHeight
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Quickshell.execDetached(["pavucontrol", "-t", "3"]);
            else
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/Volume.sh", "--toggle"]);
        }
        onWheel: event => {
            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/Volume.sh", event.angleDelta.y > 0 ? "--inc" : "--dec"]);
        }

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }

        BarText {
            id: sinkLabel
            anchors.centerIn: parent
            scale: sinkArea.pressed ? Theme.pressScale : (sinkArea.containsMouse ? Theme.hoverScale : 1.0)
            text: {
                const s = root.sink;
                if (!s || !s.audio)
                    return "󰖁";
                if (s.audio.muted)
                    return "󰖁";
                const vol = Math.round(s.audio.volume * 100);
                if (vol >= 70)
                    return "󰕾 " + vol + "%";
                if (vol >= 30)
                    return "󰖀 " + vol + "%";
                return "󰕿 " + vol + "%";
            }
        }
    }

    MouseArea {
        id: micArea
        Layout.preferredWidth: micLabel.implicitWidth + Theme.modulePadH
        Layout.preferredHeight: Theme.barHeight
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Quickshell.execDetached(["pavucontrol", "-t", "4"]);
            else
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/Volume.sh", "--toggle-mic"]);
        }
        onWheel: event => {
            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/Volume.sh", event.angleDelta.y > 0 ? "--mic-inc" : "--mic-dec"]);
        }

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }

        BarText {
            id: micLabel
            anchors.centerIn: parent
            scale: micArea.pressed ? Theme.pressScale : (micArea.containsMouse ? Theme.hoverScale : 1.0)
            text: {
                const s = root.source;
                if (!s || !s.audio)
                    return "󰍭";
                if (s.audio.muted)
                    return "󰍭";
                return "󰍬 " + Math.round(s.audio.volume * 100) + "%";
            }
        }
    }
}
