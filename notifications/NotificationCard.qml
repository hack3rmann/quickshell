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

    readonly property real cardPad: Theme.menuPad
    readonly property real iconSize: Math.round(Theme.menuRowHeight * (compact ? 1.1 : 1.4))

    radius: Theme.radius
    color: Theme.panelBg
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder
    clip: true

    implicitWidth: Math.round(360 * Theme.uiScale / 1.5)
    implicitHeight: content.implicitHeight + cardPad * 2

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
        spacing: Theme.menuPad / 2

        RowLayout {
            width: parent.width
            spacing: Theme.menuIconGap

            ResolvedIcon {
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
                Layout.alignment: Qt.AlignTop
                implicitSize: root.iconSize
                candidates: root.iconCandidates()
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    width: parent.width
                    text: root.notification ? (root.notification.appName || "Notification") : ""
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize * 0.85
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: root.notification ? (root.notification.summary || "") : ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize
                    font.bold: true
                }

                Text {
                    visible: !!(root.notification && root.notification.body)
                    width: parent.width
                    text: {
                        const b = root.notification ? (root.notification.body || "") : "";
                        // Strip simple markup for display.
                        return String(b).replace(/<[^>]+>/g, "");
                    }
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: compact ? 3 : 5
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize * 0.9
                    font.bold: true
                }
            }

            MouseArea {
                id: closeBtn
                Layout.preferredWidth: Theme.menuRowHeight
                Layout.preferredHeight: Theme.menuRowHeight
                Layout.alignment: Qt.AlignTop
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.dismissRequested()

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: closeBtn.containsMouse ? Theme.text : Theme.muted
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize
                    font.bold: true
                }
            }
        }

        // Actions
        Flow {
            visible: !!(root.notification && root.notification.actions && root.notification.actions.length)
            width: parent.width
            spacing: Theme.menuPad / 2

            Repeater {
                model: root.notification ? (root.notification.actions || []) : []

                MouseArea {
                    id: act
                    required property var modelData
                    implicitWidth: actLabel.implicitWidth + Theme.menuPad * 2
                    implicitHeight: Theme.menuRowHeight
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
                    }

                    Text {
                        id: actLabel
                        anchors.centerIn: parent
                        text: modelData.text || "Action"
                        color: act.containsMouse ? Theme.text : Theme.muted
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.menuFontPointSize * 0.9
                        font.bold: true
                    }
                }
            }
        }
    }
}
