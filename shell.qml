//@ pragma UseQApplication
//@ pragma IconTheme Adwaita
import Quickshell
import Quickshell.Io
import qs.launcher
import qs.bar
import qs.power

ShellRoot {
    id: shell

    property bool launcherOpen: false
    property bool powerMenuOpen: false
    property string focusedOutput: ""
    // "launcher" | "powermenu"
    property string pendingFocusAction: ""

    function openLauncher() {
        shell.closePowerMenu();
        shell.pendingFocusAction = "launcher";
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

    function openPowerMenu() {
        shell.closeLauncher();
        shell.pendingFocusAction = "powermenu";
        if (focusProbe.running)
            focusProbe.running = false;
        focusProbe.running = true;
    }

    function closePowerMenu() {
        powerMenuOpen = false;
    }

    function togglePowerMenu() {
        if (powerMenuOpen)
            closePowerMenu();
        else
            openPowerMenu();
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
                if (shell.pendingFocusAction === "powermenu")
                    shell.powerMenuOpen = true;
                else
                    shell.launcherOpen = true;
                shell.pendingFocusAction = "";
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
        target: "powermenu"

        function toggle(): void {
            shell.togglePowerMenu();
        }

        function open(): void {
            shell.openPowerMenu();
        }

        function close(): void {
            shell.closePowerMenu();
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

    Variants {
        model: Quickshell.screens

        PowerMenu {
            required property var modelData
            screen: modelData
            opened: shell.powerMenuOpen && modelData.name === shell.focusedOutput
            onCloseRequested: shell.closePowerMenu()
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
