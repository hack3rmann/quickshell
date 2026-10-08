pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string statePath: Quickshell.env("HOME") + "/.local/state/quickshell-launcher.json"
    readonly property var names: ["expo", "back", "quint", "quad", "cubic"]

    property string name: "expo"
    readonly property var current: presets[name] || presets.expo

    // Five snappy expand feels — cycle with Ctrl+E while the launcher is open.
    readonly property var presets: ({
            expo: {
                name: "expo",
                label: "OutExpo",
                duration: 140,
                type: Easing.OutExpo,
            },
            back: {
                name: "back",
                label: "OutBack",
                duration: 160,
                type: Easing.OutBack,
            },
            quint: {
                name: "quint",
                label: "OutQuint",
                duration: 150,
                type: Easing.OutQuint,
            },
            quad: {
                name: "quad",
                label: "OutQuad",
                duration: 110,
                type: Easing.OutQuad,
            },
            cubic: {
                name: "cubic",
                label: "OutCubic",
                duration: 100,
                type: Easing.OutCubic,
            },
        })

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.loadState(text())
    }

    function loadState(text) {
        try {
            const data = JSON.parse(text || "{}");
            if (data.easing && root.names.indexOf(data.easing) >= 0)
                root.name = data.easing;
        } catch (e) {}
    }

    function saveState() {
        let theme = "crystal";
        try {
            const existing = JSON.parse(stateFile.text() || "{}");
            if (existing.theme)
                theme = existing.theme;
        } catch (e) {}
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state"]);
        stateFile.setText(JSON.stringify({
                theme: theme,
                easing: root.name
            }, null, 2) + "\n");
    }

    function setEasing(easingName) {
        if (root.names.indexOf(easingName) < 0)
            return;
        root.name = easingName;
        saveState();
    }

    function cycle() {
        const idx = root.names.indexOf(root.name);
        setEasing(root.names[(idx + 1) % root.names.length]);
    }

    Component.onCompleted: {
        if (stateFile.loaded)
            root.loadState(stateFile.text());
    }
}
