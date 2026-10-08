pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property int cpuTempC: 0
    property int cpuUsage: 0
    property real memUsedGiB: 0
    property int diskUsedPct: 0

    property var _prevCpu: null

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            tempProc.running = true;
            cpuProc.running = true;
            memProc.running = true;
            diskProc.running = true;
        }
    }

    Process {
        id: tempProc
        command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone5/temp 2>/dev/null || cat /sys/class/thermal/thermal_zone17/temp"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const v = parseInt(text.trim(), 10);
                if (!isNaN(v))
                    root.cpuTempC = Math.round(v / 1000);
            }
        }
    }

    Process {
        id: cpuProc
        command: ["bash", "-c", "grep '^cpu ' /proc/stat"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = text.trim().split(/\s+/);
                if (parts.length < 5)
                    return;
                const idle = parseInt(parts[4], 10);
                let total = 0;
                for (let i = 1; i < parts.length; i++)
                    total += parseInt(parts[i], 10);
                if (root._prevCpu) {
                    const dTotal = total - root._prevCpu.total;
                    const dIdle = idle - root._prevCpu.idle;
                    if (dTotal > 0)
                        root.cpuUsage = Math.round(100 * (1 - dIdle / dTotal));
                }
                root._prevCpu = {
                    idle: idle,
                    total: total
                };
            }
        }
    }

    Process {
        id: memProc
        command: ["bash", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.1f\", (t-a)/1048576}' /proc/meminfo"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const v = parseFloat(text.trim());
                if (!isNaN(v))
                    root.memUsedGiB = v;
            }
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -P / | awk 'NR==2{gsub(/%/,\"\",$5); print $5}'"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const v = parseInt(text.trim(), 10);
                if (!isNaN(v))
                    root.diskUsedPct = v;
            }
        }
    }
}
