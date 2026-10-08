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

        // Ensure persistent roman slots 1–5 exist for this output.
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
        layoutProc.running = true;
    }

    function refresh() {
        wsProc.running = true;
        winProc.running = true;
        layoutProc.running = true;
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: wsProc
        command: ["niri", "msg", "-j", "workspaces"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.workspaces = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: winProc
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
        id: layoutProc
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.keyboardNames = data.names || [];
                    root.keyboardIndex = data.current_idx || 0;
                } catch (e) {}
            }
        }
    }
}
