//@ pragma UseQApplication
//@ pragma IconTheme Adwaita
import Quickshell
import Quickshell.Io
import qs.launcher
import qs.bar
import qs.notifications

ShellRoot {
    id: shell

    property bool launcherOpen: false
    property string focusedOutput: ""

    function openLauncher() {
        if (focusProbe.running)
            focusProbe.running = false;
        focusProbe.running = true;
    }

    function closeLauncher() {
        launcherOpen = false;
    }

    function toggleLauncher() {
        if (launcherOpen)
            closeLauncher();
        else
            openLauncher();
    }

    Process {
        id: focusProbe
        command: ["niri", "msg", "-j", "focused-output"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    shell.focusedOutput = JSON.parse(text).name;
                } catch (e) {
                    console.warn("focused-output parse failed:", e);
                }
                shell.launcherOpen = true;
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            shell.toggleLauncher();
        }

        function open(): void {
            shell.openLauncher();
        }

        function close(): void {
            shell.closeLauncher();
        }
    }

    IpcHandler {
        target: "notifs"

        function toggle(): void {
            Notifs.toggleCenter();
        }

        function toggleDnd(): void {
            Notifs.toggleDnd();
        }

        function clear(): void {
            Notifs.clearAll();
        }
    }

    // One launcher surface per screen (blur stays attached when switching outputs).
    Variants {
        model: Quickshell.screens

        Launcher {
            required property var modelData
            screen: modelData
            opened: shell.launcherOpen && modelData.name === shell.focusedOutput
            onCloseRequested: shell.closeLauncher()
        }
    }

    // Toast stack on every monitor.
    Variants {
        model: Quickshell.screens

        ToastStack {
            required property var modelData
            screen: modelData
        }
    }

    // Status bar on every monitor.
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
