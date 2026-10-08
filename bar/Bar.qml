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
        left: Theme.marginH
        right: Theme.marginH
    }

    implicitHeight: Theme.barHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Auto

    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacing

        // Left
        RowLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
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
            WindowTitle {}
        }

        Item {
            Layout.fillWidth: true
        }

        // Center
        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            spacing: Theme.spacing

            SwayncButton {}
            Cava {}
            Sep {
                mark: "·"
            }
            Clock {}
            Sep {
                mark: "|"
            }
            Workspaces {
                outputName: root.screen ? root.screen.name : ""
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Right
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
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
