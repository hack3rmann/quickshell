//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import qs.launcher

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

    // One surface per screen keeps background blur attached when switching outputs.
    Variants {
        model: Quickshell.screens

        Launcher {
            required property var modelData
            screen: modelData
            opened: shell.launcherOpen && modelData.name === shell.focusedOutput
            onCloseRequested: shell.closeLauncher()
        }
    }
}
