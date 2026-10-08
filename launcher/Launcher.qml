import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.launcher

PanelWindow {
    id: root

    property bool opened: false
    property int selectedIndex: 0
    property var results: []

    readonly property var theme: Themes.current

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: true

    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Empty region while closed so the fullscreen overlay does not eat clicks.
    mask: root.opened ? fullMask : emptyMask

    Region {
        id: emptyMask
    }

    Region {
        id: fullMask
        item: maskCover
    }

    Item {
        id: maskCover
        anchors.fill: parent
    }

    function refreshResults() {
        results = Search.search(searchField.text);
        selectedIndex = results.length > 0 ? 0 : -1;
    }

    function openLauncher() {
        opened = true;
        searchField.text = "";
        refreshResults();
        searchField.forceActiveFocus();
    }

    function closeLauncher() {
        opened = false;
        searchField.text = "";
        searchField.focus = false;
        results = [];
        selectedIndex = -1;
    }

    function activateSelected() {
        if (selectedIndex < 0 || selectedIndex >= results.length)
            return;
        const item = results[selectedIndex];
        if (item.type === "math") {
            Quickshell.execDetached(["wl-copy", item.value]);
            closeLauncher();
            return;
        }
        if (item.type === "app" && item.app) {
            item.app.execute();
            closeLauncher();
        }
    }

    function moveSelection(delta) {
        if (results.length === 0)
            return;
        selectedIndex = (selectedIndex + delta + results.length) % results.length;
        listView.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.opened)
                root.closeLauncher();
            else
                root.openLauncher();
        }

        function open(): void {
            root.openLauncher();
        }

        function close(): void {
            root.closeLauncher();
        }

        function setTheme(name: string): void {
            Themes.setTheme(name);
        }

        function cycleTheme(): void {
            Themes.cycleTheme();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.opened
        onActivated: root.closeLauncher()
    }

    // Dim + click-outside dismiss
    Rectangle {
        anchors.fill: parent
        color: root.theme.dim
        opacity: root.opened ? 1 : 0
        visible: root.opened

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeLauncher()
        }
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -parent.height * 0.08

        width: root.theme.width
        height: Math.min(parent.height * 0.7, root.theme.searchHeight + root.theme.padding * 2 + root.theme.spacing + root.theme.rowHeight * Math.min(Math.max(root.results.length, 1), 10) + root.theme.borderWidth * 2)
        radius: root.theme.radius
        visible: root.opened
        opacity: root.opened ? 1 : 0
        clip: true

        // Gradient border shell (niri); solid otherwise.
        color: root.theme.useGradientBorder ? "transparent" : root.theme.panelBg
        border.width: root.theme.useGradientBorder ? 0 : root.theme.borderWidth
        border.color: root.theme.panelBorder

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        // Gradient border frame
        Rectangle {
            anchors.fill: parent
            radius: root.theme.radius
            visible: root.theme.useGradientBorder
            z: -1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: root.theme.gradientStart
                }
                GradientStop {
                    position: 1.0
                    color: root.theme.gradientEnd
                }
            }
        }

        Rectangle {
            id: panelInner
            anchors.fill: parent
            anchors.margins: root.theme.useGradientBorder ? root.theme.borderWidth : 0
            radius: Math.max(0, root.theme.radius - (root.theme.useGradientBorder ? root.theme.borderWidth : 0))
            color: root.theme.panelBg
            clip: true

            MouseArea {
                anchors.fill: parent
                // Consume clicks so dim overlay doesn't close when interacting with panel.
                onClicked: searchField.forceActiveFocus()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.theme.padding
                spacing: root.theme.spacing

                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    height: root.theme.searchHeight
                    radius: Math.max(4, root.theme.radius - 4)
                    color: root.theme.inputBg
                    border.width: searchField.activeFocus ? 1 : 0
                    border.color: root.theme.accent

                    TextField {
                        id: searchField
                        anchors.fill: parent
                        anchors.leftMargin: root.theme.padding
                        anchors.rightMargin: root.theme.padding
                        color: root.theme.text
                        placeholderText: "search apps  ·  math  ·  ctrl+t theme"
                        placeholderTextColor: root.theme.muted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                        font.bold: true
                        background: null
                        selectByMouse: true

                        onTextChanged: root.refreshResults()

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                root.moveSelection(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.moveSelection(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab) {
                                if (event.modifiers & Qt.ControlModifier) {
                                    Themes.cycleTheme();
                                } else if (event.modifiers & Qt.ShiftModifier) {
                                    root.moveSelection(-1);
                                } else {
                                    root.moveSelection(1);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Backtab) {
                                // Some platforms emit Backtab for Shift+Tab
                                root.moveSelection(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.activateSelected();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                root.closeLauncher();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_T && (event.modifiers & Qt.ControlModifier)) {
                                Themes.cycleTheme();
                                event.accepted = true;
                            }
                        }
                    }
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: Math.max(2, Math.round(2 * Themes.uiScale))
                    model: root.results
                    currentIndex: root.selectedIndex
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index

                        width: listView.width
                        height: root.theme.rowHeight

                        readonly property bool selected: index === root.selectedIndex

                        Rectangle {
                            anchors.fill: parent
                            radius: Math.max(4, root.theme.radius - 4)
                            color: row.selected ? root.theme.selectBg : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.theme.padding
                            anchors.rightMargin: root.theme.padding
                            spacing: root.theme.padding


                            IconImage {
                                visible: row.modelData.type === "app"
                                Layout.preferredWidth: root.theme.iconSize
                                Layout.preferredHeight: root.theme.iconSize
                                implicitSize: root.theme.iconSize
                                source: {
                                    if (row.modelData.type !== "app" || !row.modelData.app)
                                        return "";
                                    return Quickshell.iconPath(row.modelData.app.icon, "application-x-executable");
                                }
                            }

                            IconImage {
                                visible: row.modelData.type === "math"
                                Layout.preferredWidth: root.theme.iconSize
                                Layout.preferredHeight: root.theme.iconSize
                                implicitSize: root.theme.iconSize
                                source: Quickshell.iconPath("accessories-calculator", "application-x-executable")
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                    color: root.theme.text
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: root.theme.fontSize
                                    font.bold: row.selected
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: !!row.modelData.subtitle && (row.selected || row.modelData.type === "math")
                                    text: row.modelData.subtitle
                                    color: root.theme.muted
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: root.theme.subtitleSize
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                visible: row.selected
                                text: row.modelData.type === "math" ? "copy" : "launch"
                                color: root.theme.muted
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.subtitleSize
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selectedIndex = row.index
                            onClicked: {
                                root.selectedIndex = row.index;
                                root.activateSelected();
                            }
                        }
                    }
                }
            }
        }
    }
}
