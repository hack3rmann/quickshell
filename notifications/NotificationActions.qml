import QtQuick
import qs.bar

Item {
    id: root

    property var notification: null
    property real cardPad: Theme.menuPad
    property real actionHeight: Theme.menuRowHeight

    signal invoked

    readonly property bool hasActions: !!(notification && notification.actions && notification.actions.length)
    readonly property var actionModel: notification ? (notification.actions || []) : []

    visible: hasActions
    implicitWidth: width
    implicitHeight: visible ? chips.implicitHeight : 0
    height: implicitHeight

    function runAction(action) {
        try {
            action.invoke();
        } catch (e) {}
        root.invoked();
    }

    Flow {
        id: chips
        width: parent.width
        spacing: Math.max(4, Math.round(root.cardPad * 0.5))
        topPadding: Math.max(4, Math.round(root.cardPad * 0.6))

        Repeater {
            model: root.actionModel

            MouseArea {
                id: chip
                required property var modelData
                implicitWidth: chipLabel.implicitWidth + root.cardPad * 2
                implicitHeight: root.actionHeight
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.runAction(modelData)

                Rectangle {
                    anchors.fill: parent
                    radius: Math.max(4, Theme.radius - 4)
                    color: chip.containsMouse ? Theme.selectBg : Qt.rgba(1, 1, 1, 0.06)
                    border.width: Math.max(1, Math.round(Theme.borderWidth * 0.75))
                    border.color: chip.containsMouse ? Theme.panelBorder : Qt.rgba(1, 1, 1, 0.16)

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: modelData.text || "Action"
                    color: chip.containsMouse ? Theme.text : Theme.muted
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize * 0.9
                    font.bold: true
                    scale: chip.pressed ? Theme.pressScale : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
