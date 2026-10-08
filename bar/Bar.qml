import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.bar
import qs.bar.modules

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.marginTop
        bottom: Theme.marginBottom
        left: Theme.marginH
        right: Theme.marginH
    }

    implicitHeight: Theme.barHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Auto

    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top

    // Absolute screen-center for the middle cluster (not balanced against L/R widths).
    Item {
        id: content
        anchors.fill: parent

        RowLayout {
            id: leftRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacing

            Battery {}
            Sep {
                mark: "|"
            }
            PerfProfile {}
            MoboDrawer {}
            Sep {
                mark: "|"
            }
            WindowTitle {
                id: windowTitle
                // Elide only once the title would collide with the centered cluster.
                maxWidth: Math.max(0, centerRow.x - (leftRow.x + windowTitle.x) - Theme.spacing)
            }
        }

        RowLayout {
            id: centerRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacing

            SwayncButton {}
            Cava {}
            Sep {
                mark: "|"
            }
            Clock {}
            Sep {
                mark: "|"
            }
            Workspaces {
                outputName: root.screen ? root.screen.name : ""
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacing

            Network {}
            Bluetooth {}
            Sep {
                mark: "|"
            }
            Audio {}
            Sep {
                mark: "|"
            }
            KeyboardLayout {}
            PowerButton {}
        }
    }
}
