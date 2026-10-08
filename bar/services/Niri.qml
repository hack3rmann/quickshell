pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var workspaces: []
    property int workspacesRev: 0
    property string focusedTitle: ""
    property string focusedAppId: ""
    property var keyboardNames: []
    property int keyboardIndex: 0

    readonly property string layoutShort: {
        const names = root.keyboardNames;
        if (!names.length)
            return "";
        const name = names[root.keyboardIndex] || "";
        if (name.indexOf("Russian") >= 0)
            return "ru";
        if (name.indexOf("English") >= 0 || name.indexOf("US") >= 0)
            return "us";
        return name.split(" ")[0].toLowerCase().slice(0, 2);
    }

    function applyFocusedFromWindows(windows) {
        if (!windows || !windows.length) {
            root.focusedTitle = "";
            root.focusedAppId = "";
            return;
        }
        for (let i = 0; i < windows.length; i++) {
            if (windows[i].is_focused) {
                root.focusedTitle = windows[i].title || "";
                root.focusedAppId = windows[i].app_id || "";
                return;
            }
        }
        root.focusedTitle = "";
        root.focusedAppId = "";
    }

    function setWorkspaces(list) {
        root.workspaces = list || [];
        root.workspacesRev++;
    }

    // Real workspaces on this output only (niri is dynamic — no fake I–V slots).
    function workspacesForOutput(outputName) {
        const all = root.workspaces || [];
        const filtered = [];
        for (let i = 0; i < all.length; i++) {
            if (all[i].output === outputName)
                filtered.push(all[i]);
        }
        filtered.sort(function (a, b) {
            return a.idx - b.idx;
        });
        return filtered;
    }

    // focus-workspace is per focused monitor — must focus the output first, sequentially.
    function focusWorkspace(ws) {
        if (!ws || !ws.idx)
            return;
        const out = ws.output || "";
        if (out) {
            Quickshell.execDetached([
                "bash", "-c",
                "niri msg action focus-monitor " + JSON.stringify(out)
                    + " && niri msg action focus-workspace " + String(ws.idx)
            ]);
        } else {
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(ws.idx)]);
        }
    }

    function cycleLayout() {
        Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"]);
        // Event stream updates keyboardIndex via KeyboardLayoutSwitched.
    }

    function refreshLayouts() {
        layoutProbe.running = true;
    }

    function refreshWorkspaces() {
        wsProbe.running = true;
    }

    function handleEvent(line) {
        if (!line || !line.trim())
            return;
        try {
            const ev = JSON.parse(line);
            if (ev.WorkspacesChanged)
                root.setWorkspaces(ev.WorkspacesChanged.workspaces || []);
            // Mod+N switches emit this without a full WorkspacesChanged dump.
            if (ev.WorkspaceActivated)
                root.refreshWorkspaces();
            if (ev.WindowsChanged)
                root.applyFocusedFromWindows(ev.WindowsChanged.windows || []);
            if (ev.WindowOpenedOrChanged && ev.WindowOpenedOrChanged.window) {
                const w = ev.WindowOpenedOrChanged.window;
                if (w.is_focused) {
                    root.focusedTitle = w.title || "";
                    root.focusedAppId = w.app_id || "";
                }
            }
            if (ev.WindowFocusChanged)
                winProbe.running = true;
            if (ev.KeyboardLayoutsChanged && ev.KeyboardLayoutsChanged.keyboard_layouts) {
                const kb = ev.KeyboardLayoutsChanged.keyboard_layouts;
                root.keyboardNames = kb.names || [];
                root.keyboardIndex = kb.current_idx ?? 0;
            }
            // Click / hotkey switch emits this (not a full KeyboardLayoutsChanged).
            if (ev.KeyboardLayoutSwitched && ev.KeyboardLayoutSwitched.idx !== undefined)
                root.keyboardIndex = ev.KeyboardLayoutSwitched.idx;
        } catch (e) {}
    }

    Process {
        id: eventStream
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.handleEvent(data)
        }
    }

    Process {
        id: wsProbe
        command: ["niri", "msg", "-j", "workspaces"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.setWorkspaces(JSON.parse(text));
                } catch (e) {}
            }
        }
    }

    Process {
        id: winProbe
        command: ["niri", "msg", "-j", "focused-window"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    if (!text || !text.trim() || text.trim() === "null") {
                        root.focusedTitle = "";
                        root.focusedAppId = "";
                        return;
                    }
                    const w = JSON.parse(text);
                    root.focusedTitle = w.title || "";
                    root.focusedAppId = w.app_id || "";
                } catch (e) {
                    root.focusedTitle = "";
                    root.focusedAppId = "";
                }
            }
        }
    }

    Process {
        id: layoutProbe
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const kb = JSON.parse(text);
                    root.keyboardNames = kb.names || [];
                    root.keyboardIndex = kb.current_idx ?? 0;
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: {
        wsProbe.running = true;
        winProbe.running = true;
        layoutProbe.running = true;
    }
}
