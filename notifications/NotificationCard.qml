import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.bar.modules

Rectangle {
    id: root

    property var notification: null
    property bool compact: false
    signal dismissRequested
    signal closeRequested

    readonly property real cardPad: compact ? Math.max(6, Math.round(Theme.menuPad * 0.7)) : Theme.menuPad
    readonly property real iconSize: Math.round((compact ? 18 : 24) * Theme.uiScale / 1.5)
    readonly property real closeSize: Math.round((compact ? 20 : 24) * Theme.uiScale / 1.5)
    readonly property real actionHeight: compact ? Math.round(22 * Theme.uiScale / 1.5) : Theme.menuRowHeight
    readonly property bool hasActions: !!(notification && notification.actions && notification.actions.length)

    radius: Theme.radius
    color: Theme.panelBg
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder
    clip: true
    scale: hover.containsMouse ? 1.015 : 1.0
    transformOrigin: Item.Center

    // Shrink-wrap to content — no artificial min height from layout stretch.
    implicitWidth: Math.round(360 * Theme.uiScale / 1.5)
    implicitHeight: content.implicitHeight + cardPad * 2
    height: implicitHeight

    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.selectBg
        opacity: hover.containsMouse ? 1 : 0
        z: -1

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }
    }

    function iconCandidates() {
        const n = root.notification;
        if (!n)
            return [];
        if (n.image)
            return Theme.iconCandidates(n.image);
        if (n.appIcon)
            return Theme.iconCandidates(n.appIcon);
        if (n.desktopEntry)
            return Theme.iconCandidates(n.desktopEntry);
        return Theme.iconCandidates("preferences-system-notifications-symbolic");
    }

    Column {
        id: content
        x: root.cardPad
        y: root.cardPad
        width: parent.width - root.cardPad * 2
        spacing: Math.max(2, Math.round(root.cardPad * 0.4))

        RowLayout {
            width: parent.width
            spacing: Theme.menuIconGap
            // Keep the row as tall as its children — no stretch floor.
            implicitHeight: Math.max(root.iconSize, textCol.implicitHeight, root.closeSize)

            ResolvedIcon {
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
                Layout.maximumWidth: root.iconSize
                Layout.maximumHeight: root.iconSize
                Layout.alignment: Qt.AlignTop
                implicitSize: root.iconSize
                candidates: root.iconCandidates()
            }

            Column {
                id: textCol
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                    width: parent.width
                    visible: text.length > 0
                    height: visible ? implicitHeight : 0
                    text: root.notification ? (root.notification.appName || "") : ""
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize * 0.8
                    font.bold: true
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    height: visible ? implicitHeight : 0
                    text: root.notification ? (root.notification.summary || "") : ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize * (compact ? 0.95 : 1.0)
                    font.bold: true
                }

                Text {
                    visible: !!(root.notification && root.notification.body)
                    height: visible ? implicitHeight : 0
                    width: parent.width
                    text: {
                        const b = root.notification ? (root.notification.body || "") : "";
                        return String(b).replace(/<[^>]+>/g, "");
                    }
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: compact ? 3 : 5
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize * 0.85
                    font.bold: true
                }
            }

            MouseArea {
                id: closeBtn
                Layout.preferredWidth: root.closeSize
                Layout.preferredHeight: root.closeSize
                Layout.maximumWidth: root.closeSize
                Layout.maximumHeight: root.closeSize
                Layout.alignment: Qt.AlignTop
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.dismissRequested()

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: closeBtn.containsMouse ? Theme.text : Theme.muted
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize * (compact ? 0.9 : 1.0)
                    font.bold: true
                    scale: closeBtn.pressed ? Theme.pressScale : (closeBtn.containsMouse ? Theme.hoverScale : 1.0)

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

        Rectangle {
            visible: root.hasActions
            height: visible ? 1 : 0
            width: parent.width
            color: Qt.rgba(1, 1, 1, 0.25)
        }

        Flow {
            visible: root.hasActions
            height: visible ? implicitHeight : 0
            width: parent.width
            spacing: Math.max(2, Math.round(root.cardPad * 0.4))

            Repeater {
                model: root.notification ? (root.notification.actions || []) : []

                MouseArea {
                    id: act
                    required property var modelData
                    implicitWidth: actLabel.implicitWidth + root.cardPad * 2
                    implicitHeight: root.actionHeight
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        try {
                            modelData.invoke();
                        } catch (e) {}
                        root.closeRequested();
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.max(4, Theme.radius - 4)
                        color: act.containsMouse ? Theme.selectBg : "transparent"
                        border.width: act.containsMouse ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
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
                        id: actLabel
                        anchors.centerIn: parent
                        text: modelData.text || "Action"
                        color: act.containsMouse ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize * 0.9
                        font.bold: true
                        scale: act.pressed ? Theme.pressScale : 1.0

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
}
