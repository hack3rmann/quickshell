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
    // Grows to 2× list height once the selection reaches the 10th row.
    property bool listExpanded: false

    signal closeRequested

    readonly property var theme: Themes.current
    readonly property int maxVisibleRows: listExpanded ? 20 : 10

    onSelectedIndexChanged: {
        if (selectedIndex >= 9)
            listExpanded = true;
    }

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

    // Blur only behind the panel (not the whole screen).
    BackgroundEffect.blurRegion: root.opened ? blurRegion : null

    // Empty region while closed so the fullscreen overlay does not eat clicks.
    mask: root.opened ? fullMask : emptyMask

    Region {
        id: emptyMask
    }

    Region {
        id: fullMask
        item: maskCover
    }

    Region {
        id: blurRegion
        item: panel
        radius: root.theme.radius
    }

    Item {
        id: maskCover
        anchors.fill: parent
    }

    function refreshResults() {
        results = Search.search(searchField.text);
        selectedIndex = results.length > 0 ? 0 : -1;
    }

    function requestClose() {
        root.closeRequested();
    }

    onOpenedChanged: {
        if (opened) {
            listExpanded = false;
            searchField.text = "";
            refreshResults();
            searchField.forceActiveFocus();
            if (results.length === 0)
                appsReadyRetry.restart();
            // Re-apply blur after layout so the region matches the panel geometry.
            blurKick.restart();
        } else {
            appsReadyRetry.stop();
            blurKick.stop();
            listExpanded = false;
            searchField.text = "";
            searchField.focus = false;
            results = [];
            selectedIndex = -1;
        }
    }

    Timer {
        id: blurKick
        interval: 16
        repeat: false
        onTriggered: {
            if (!root.opened)
                return;
            BackgroundEffect.blurRegion = null;
            BackgroundEffect.blurRegion = blurRegion;
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            if (root.opened)
                root.refreshResults();
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            if (root.opened)
                root.refreshResults();
        }
    }

    Timer {
        id: appsReadyRetry
        property int attempts: 0
        interval: 150
        repeat: true
        onRunningChanged: if (running)
            attempts = 0
        onTriggered: {
            if (!root.opened) {
                stop();
                return;
            }
            attempts += 1;
            root.refreshResults();
            if (root.results.length > 0 || DesktopEntries.applications.values.length > 0 || attempts >= 40)
                stop();
        }
    }

    function activateSelected() {
        if (selectedIndex < 0 || selectedIndex >= results.length)
            return;
        const item = results[selectedIndex];
        if (item.type === "math") {
            Quickshell.execDetached(["wl-copy", item.value]);
            requestClose();
            return;
        }
        if (item.type === "app" && item.app) {
            item.app.execute();
            requestClose();
        }
    }

    function moveSelection(delta) {
        if (results.length === 0)
            return;
        selectedIndex = (selectedIndex + delta + results.length) % results.length;
        listView.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    // Bundled SVGs — theme iconPath fallbacks often resolve to Qt's checkerboard texture.
    readonly property string defaultAppIcon: Qt.resolvedUrl(Quickshell.shellPath("assets/app-default.svg"))
    readonly property string mathIcon: Qt.resolvedUrl(Quickshell.shellPath("assets/math.svg"))

    function appIconSource(app) {
        if (!app)
            return root.defaultAppIcon;
        const icon = (app.icon || "").trim();
        if (!icon)
            return root.defaultAppIcon;
        // check=true returns "" instead of the missing-texture placeholder
        const path = Quickshell.iconPath(icon, true);
        return path ? path : root.defaultAppIcon;
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.opened
        onActivated: root.requestClose()
    }

    // Transparent click-catcher so the rest of the desktop stays visible.
    MouseArea {
        anchors.fill: parent
        visible: root.opened
        onClicked: root.requestClose()
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -parent.height * 0.08

        width: root.theme.width
        height: Math.min(parent.height * 0.85, root.theme.searchHeight + root.theme.padding * 2 + root.theme.spacing + root.theme.rowHeight * Math.min(Math.max(root.results.length, 1), root.maxVisibleRows) + root.theme.borderWidth * 2)
        radius: root.theme.radius
        visible: root.opened
        opacity: root.opened ? 1 : 0
        clip: true
        color: root.theme.panelBg
        border.width: root.theme.borderWidth
        border.color: root.theme.panelBorder

        Behavior on height {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
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
                    placeholderText: "search apps  ·  math"
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
                            if (event.modifiers & Qt.ShiftModifier)
                                root.moveSelection(-1);
                            else
                                root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backtab) {
                            root.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activateSelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.requestClose();
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
                        color: "transparent"
                        border.width: row.selected ? Math.max(1, Math.round(root.theme.borderWidth * 0.75)) : 0
                        border.color: root.theme.panelBorder
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.theme.padding
                        anchors.rightMargin: root.theme.padding
                        spacing: root.theme.padding

                        IconImage {
                            id: appIcon
                            visible: row.modelData.type === "app"
                            Layout.preferredWidth: root.theme.iconSize
                            Layout.preferredHeight: root.theme.iconSize
                            implicitSize: root.theme.iconSize
                            asynchronous: true
                            source: row.modelData.type === "app" ? root.appIconSource(row.modelData.app) : ""
                            onStatusChanged: {
                                // Absolute paths / broken files may still fail after a non-empty iconPath.
                                if (status === Image.Error && source !== root.defaultAppIcon)
                                    source = root.defaultAppIcon;
                            }
                        }

                        IconImage {
                            visible: row.modelData.type === "math"
                            Layout.preferredWidth: root.theme.iconSize
                            Layout.preferredHeight: root.theme.iconSize
                            implicitSize: root.theme.iconSize
                            source: root.mathIcon
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
