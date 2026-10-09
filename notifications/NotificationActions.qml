import QtQuick
import qs.bar

// Action row variants — cycle with A while the notification center is open.
Item {
    id: root

    property var notification: null
    property real cardPad: Theme.menuPad
    property real actionHeight: Theme.menuRowHeight
    // chips | bleed | links | gap | rail
    property string style: Notifs.actionStyle

    signal invoked

    readonly property bool hasActions: !!(notification && notification.actions && notification.actions.length)
    readonly property var actionModel: notification ? (notification.actions || []) : []

    visible: hasActions
    implicitWidth: width
    implicitHeight: visible ? stack.implicitHeight : 0
    height: implicitHeight
    clip: style === "bleed"

    function runAction(action) {
        try {
            action.invoke();
        } catch (e) {}
        root.invoked();
    }

    Item {
        id: stack
        width: parent.width
        implicitHeight: {
            if (!root.hasActions)
                return 0;
            if (root.style === "chips")
                return chips.implicitHeight;
            if (root.style === "bleed")
                return bleed.implicitHeight;
            if (root.style === "links")
                return links.implicitHeight;
            if (root.style === "gap")
                return gap.implicitHeight;
            return rail.implicitHeight;
        }
        height: implicitHeight

        // 1) Soft always-on chips, air gap only (no band / no rule).
        Flow {
            id: chips
            visible: root.style === "chips"
            width: parent.width
            height: visible ? implicitHeight : 0
            spacing: Math.max(4, Math.round(root.cardPad * 0.5))
            topPadding: Math.max(4, Math.round(root.cardPad * 0.6))

            Repeater {
                model: root.actionModel
                delegate: actionChip
            }
        }

        // 2) Full-bleed bottom strip (flush to card edges).
        Rectangle {
            id: bleed
            visible: root.style === "bleed"
            width: parent.width
            height: visible ? implicitHeight : 0
            implicitHeight: bleedFlow.implicitHeight + root.cardPad
            color: Qt.rgba(1, 1, 1, 0.08)

            Flow {
                id: bleedFlow
                x: root.cardPad
                y: root.cardPad * 0.5
                width: parent.width - root.cardPad * 2
                spacing: Math.max(4, Math.round(root.cardPad * 0.5))

                Repeater {
                    model: root.actionModel
                    delegate: actionChip
                }
            }
        }

        // 3) Text links — quiet, underline on hover.
        Flow {
            id: links
            visible: root.style === "links"
            width: parent.width
            height: visible ? implicitHeight : 0
            spacing: Math.max(10, Math.round(root.cardPad * 1.2))
            topPadding: Math.max(6, Math.round(root.cardPad * 0.75))

            Repeater {
                model: root.actionModel

                MouseArea {
                    id: link
                    required property var modelData
                    implicitWidth: linkLabel.implicitWidth
                    implicitHeight: linkLabel.implicitHeight + 2
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.runAction(modelData)

                    Text {
                        id: linkLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        text: modelData.text || "Action"
                        color: link.containsMouse ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize * 0.9
                        font.bold: true
                        font.underline: link.containsMouse

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }

        // 4) Hover-only chips + generous gap (original loose layout).
        Flow {
            id: gap
            visible: root.style === "gap"
            width: parent.width
            height: visible ? implicitHeight : 0
            spacing: Math.max(4, Math.round(root.cardPad * 0.5))
            topPadding: Math.max(8, Math.round(root.cardPad * 1.1))

            Repeater {
                model: root.actionModel
                delegate: actionGhostChip
            }
        }

        // 5) Full-width stacked rows (settings-list feel).
        Column {
            id: rail
            visible: root.style === "rail"
            width: parent.width
            height: visible ? implicitHeight : 0
            spacing: 0
            topPadding: Math.max(4, Math.round(root.cardPad * 0.5))

            Repeater {
                model: root.actionModel

                MouseArea {
                    id: row
                    required property var modelData
                    required property int index
                    width: rail.width
                    implicitHeight: root.actionHeight + 4
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.runAction(modelData)

                    Rectangle {
                        anchors.fill: parent
                        color: row.containsMouse ? Theme.selectBg : "transparent"
                        radius: Math.max(4, Theme.radius - 4)

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        visible: index > 0
                        width: parent.width
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.12)
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: root.cardPad * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.text || "Action"
                        color: row.containsMouse ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize * 0.9
                        font.bold: true

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: actionChip

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

    Component {
        id: actionGhostChip

        MouseArea {
            id: ghost
            required property var modelData
            implicitWidth: ghostLabel.implicitWidth + root.cardPad * 2
            implicitHeight: root.actionHeight
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.runAction(modelData)

            Rectangle {
                anchors.fill: parent
                radius: Math.max(4, Theme.radius - 4)
                color: ghost.containsMouse ? Theme.selectBg : "transparent"
                border.width: ghost.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                border.color: Theme.panelBorder

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on border.width {
                    NumberAnimation {
                        duration: Theme.animFast
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                id: ghostLabel
                anchors.centerIn: parent
                text: modelData.text || "Action"
                color: ghost.containsMouse ? Theme.text : Theme.muted
                font.family: Theme.fontFamily
                font.pointSize: Theme.menuFontPointSize * 0.9
                font.bold: true
                scale: ghost.pressed ? Theme.pressScale : 1.0

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
