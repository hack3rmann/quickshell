import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.bar

// One level of a StatusNotifier / DBus menu, styled like the launcher.
Column {
    id: root

    required property var menuHandle
    signal activated

    spacing: 2

    // Measure strings — avoid binding loops from stretching children to Column width.
    readonly property real menuWidth: {
        let w = Theme.menuPad * 4;
        const kids = opener.children ? opener.children.values : [];
        for (let i = 0; i < kids.length; i++) {
            const e = kids[i];
            if (!e || e.isSeparator)
                continue;
            let ew = fm.advanceWidth(root.clean(e.text)) + Theme.menuPad * 2;
            if (e.buttonType !== QsMenuButtonType.None || Theme.iconCandidates(e.icon).length)
                ew += Theme.menuRowHeight * 0.7 + Theme.spacing;
            if (e.hasChildren)
                ew += Theme.menuRowHeight * 0.6;
            w = Math.max(w, ew);
        }
        return Math.max(w, Theme.menuPad * 12);
    }

    function clean(s) {
        return String(s || "").replace(/_([^_])/g, "$1");
    }

    FontMetrics {
        id: fm
        font.family: Theme.fontFamily
        font.pointSize: Theme.menuFontPointSize
        font.bold: true
    }

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    Repeater {
        model: opener.children

        Item {
            id: row
            required property var modelData
            readonly property var entry: modelData
            readonly property bool interactive: entry && entry.enabled && !entry.isSeparator
            readonly property bool hovered: rowHover.hovered && interactive
            property bool expanded: false

            width: root.width
            height: entry && entry.isSeparator ? Theme.menuPad : (Theme.menuRowHeight + (expanded && subLoader.item ? subLoader.item.implicitHeight : 0))

            // Separator
            Rectangle {
                visible: row.entry && row.entry.isSeparator
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.menuPad
                anchors.rightMargin: Theme.menuPad
                height: 1
                color: Qt.rgba(1, 1, 1, 0.25)
            }

            // Entry row
            Item {
                id: line
                width: parent.width
                height: row.entry && row.entry.isSeparator ? 0 : Theme.menuRowHeight
                visible: row.entry && !row.entry.isSeparator

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    radius: Math.max(4, Theme.radius - 4)
                    color: row.hovered ? Theme.selectBg : "transparent"
                    border.width: row.hovered ? Math.max(1, Math.round(Theme.borderWidth * 0.75)) : 0
                    border.color: Theme.panelBorder

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Item {
                    id: leading
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.menuPad
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property bool showCheck: !!(row.entry && row.entry.buttonType !== QsMenuButtonType.None)
                    readonly property var iconTries: row.entry ? Theme.iconCandidates(row.entry.icon) : []
                    // Collapse the leading slot entirely when there is nothing to show.
                    width: (showCheck || entryIcon.ready) ? Theme.menuRowHeight * 0.65 : 0
                    height: width

                    Rectangle {
                        anchors.centerIn: parent
                        visible: leading.showCheck
                        width: parent.width * 0.7
                        height: width
                        radius: row.entry && row.entry.buttonType === QsMenuButtonType.RadioButton ? width / 2 : 2
                        border.width: 1
                        border.color: Theme.text
                        color: row.entry && row.entry.checkState === Qt.Checked ? Theme.text : "transparent"

                        Text {
                            anchors.centerIn: parent
                            visible: row.entry && row.entry.buttonType === QsMenuButtonType.CheckBox && row.entry.checkState === Qt.Checked
                            text: "✓"
                            color: Theme.panelBg
                            font.pixelSize: Math.round(parent.width * 0.75)
                            font.bold: true
                        }
                    }

                    ResolvedIcon {
                        id: entryIcon
                        anchors.centerIn: parent
                        candidates: leading.showCheck ? [] : leading.iconTries
                        implicitSize: Math.round(Math.max(1, parent.width || Theme.menuRowHeight * 0.65))
                        // Menu glyphs are nearly always dark symbolic icons.
                        forceMono: true
                    }
                }

                Text {
                    anchors.left: leading.right
                    anchors.leftMargin: leading.width > 0 ? Theme.spacing : Theme.menuPad
                    anchors.right: arrow.left
                    anchors.rightMargin: Theme.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.clean(row.entry ? row.entry.text : "")
                    elide: Text.ElideRight
                    color: !row.entry || !row.entry.enabled ? Theme.muted : Theme.text
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize
                    font.bold: true
                }

                Text {
                    id: arrow
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.menuPad
                    anchors.verticalCenter: parent.verticalCenter
                    width: row.entry && row.entry.hasChildren ? Theme.menuRowHeight * 0.5 : 0
                    visible: row.entry && row.entry.hasChildren
                    text: row.expanded ? "▾" : "▸"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.menuFontPointSize
                    font.bold: true
                }

                HoverHandler {
                    id: rowHover
                    enabled: row.interactive
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    enabled: row.interactive
                    onTapped: {
                        if (row.entry.hasChildren) {
                            row.expanded = !row.expanded;
                            return;
                        }
                        row.entry.triggered();
                        root.activated();
                    }
                }
            }

            Item {
                id: sub
                anchors.top: line.bottom
                width: parent.width
                height: row.expanded && subLoader.item ? subLoader.item.implicitHeight : 0
                clip: true
                visible: height > 0

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.animFast
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    x: Theme.menuPad / 2
                    width: 1
                    height: parent.height
                    color: Qt.rgba(1, 1, 1, 0.2)
                }

                Loader {
                    id: subLoader
                    x: Theme.menuPad
                    width: parent.width - Theme.menuPad
                    onLoaded: item.activated.connect(root.activated)
                }

                Connections {
                    target: row
                    function onExpandedChanged() {
                        if (row.expanded)
                            subLoader.setSource(Qt.resolvedUrl("TrayMenuList.qml"), {
                                menuHandle: row.entry
                            });
                        else
                            subLoader.source = "";
                    }
                }
            }
        }
    }
}
