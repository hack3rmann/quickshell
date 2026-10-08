pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var workspaces: []
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

        const byIdx = {};
        for (let j = 0; j < filtered.length; j++)
            byIdx[filtered[j].idx] = filtered[j];

        const result = [];
        const maxIdx = Math.max(5, filtered.length ? filtered[filtered.length - 1].idx : 5);
        for (let idx = 1; idx <= maxIdx; idx++) {
            if (byIdx[idx]) {
                result.push(byIdx[idx]);
            } else if (idx <= 5) {
                result.push({
                    id: -idx,
                    idx: idx,
                    output: outputName,
                    is_active: false,
                    is_focused: false,
                    is_urgent: false,
                    placeholder: true,
                });
            }
        }
        return result;
    }

    function focusWorkspace(ws) {
        if (!ws || ws.placeholder)
            return;
        if (ws.output)
            Quickshell.execDetached(["niri", "msg", "action", "focus-monitor", ws.output]);
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(ws.idx)]);
    }

    function cycleLayout() {
        Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"]);
    }

    function handleEvent(line) {
        if (!line || !line.trim())
            return;
        try {
            const ev = JSON.parse(line);
            if (ev.WorkspacesChanged)
                root.workspaces = ev.WorkspacesChanged.workspaces || [];
            if (ev.WindowsChanged)
                root.applyFocusedFromWindows(ev.WindowsChanged.windows || []);
            if (ev.WindowOpenedOrChanged && ev.WindowOpenedOrChanged.window) {
                const w = ev.WindowOpenedOrChanged.window;
                if (w.is_focused) {
                    root.focusedTitle = w.title || "";
                    root.focusedAppId = w.app_id || "";
                }
            }
            if (ev.WindowFocusChanged) {
                // Focus id alone — refresh from a quick focused-window probe.
                winProbe.running = true;
            }
            if (ev.KeyboardLayoutsChanged && ev.KeyboardLayoutsChanged.keyboard_layouts) {
                const kb = ev.KeyboardLayoutsChanged.keyboard_layouts;
                root.keyboardNames = kb.names || [];
                root.keyboardIndex = kb.current_idx || 0;
            }
        } catch (e) {}
    }

    // Live compositor events — title/workspaces update immediately.
    Process {
        id: eventStream
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.handleEvent(data)
        }
    }

    // Fallback when only a focus id is emitted.
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

    Component.onCompleted: winProbe.running = true
}
