import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../services"
import "../../components"

ScrollPage {
    id: root
    title: "Power history"
    property int hours: 24
    property var report: ({charge: [], rate: [], apps: [], current: {}, coverage: 0, now: 0, start: 0, last_sample: 0})
    property string error: ""
    readonly property var discharge: root.report.rate.filter(point => point.state === 2)
    readonly property real maxWatts: Math.max(10, ...root.discharge.map(point => point.value * 1.1))
    readonly property bool recording: root.report.last_sample > 0 && root.report.now - root.report.last_sample < 120
    readonly property string currentDraw: {
        const current = root.report.current;
        if (current.status === "Discharging" && current.watts !== null && current.watts !== undefined)
            return current.watts.toFixed(1) + " W on battery";
        if (current.status === "Unavailable") return "Battery unavailable";
        return "Plugged in · battery draw does not measure wall power";
    }

    function duration(seconds: real): string {
        if (seconds < 60) return Math.round(seconds) + " sec";
        if (seconds < 3600) return (seconds/60).toFixed(1) + " min";
        return (seconds/3600).toFixed(1) + " h";
    }
    function refresh(): void {
        if (!reader.running) {
            reader.requestedHours = root.hours;
            reader.running = true;
        }
    }
    onHoursChanged: refresh()

    Process {
        id: reader
        property int requestedHours: 24
        command: ["python3", Directories.repoRoot + "/scripts/power-history.py", "report", "--hours", String(requestedHours)]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (!Array.isArray(data.charge) || !Array.isArray(data.rate) || !Array.isArray(data.apps))
                        throw new Error("Invalid report");
                    root.report = data;
                    root.error = "";
                } catch (e) {
                    root.error = "Power history could not be loaded";
                }
            }
        }
        onExited: code => {
            if (code !== 0) root.error = "Power history could not be loaded";
            if (reader.requestedHours !== root.hours) root.refresh();
        }
    }
    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    SettingGroup {
        SettingRow {
            first: true
            last: true
            live: true
            label: "History period"
            subtext: root.currentDraw
            SelectMenu {
                options: [
                    {value: "1", label: "Last hour"},
                    {value: "24", label: "Last 24 hours"},
                    {value: "168", label: "Last 7 days"},
                    {value: "720", label: "Last 30 days"}
                ]
                current: String(root.hours)
                onSelected: value => root.hours = Number(value)
            }
        }
    }
    StyledText {
        Layout.fillWidth: true
        visible: root.error.length > 0
        text: root.error
        color: Colors.error
        wrapMode: Text.Wrap
    }
    PowerHistoryChart {
        title: "Battery level"
        points: root.report.charge
        startTime: root.report.start
        endTime: root.report.now
    }
    PowerHistoryChart {
        title: "Power draw on battery"
        points: root.report.rate
        startTime: root.report.start
        endTime: root.report.now
        dischargeOnly: true
        unit: "W"
        maximum: root.maxWatts
    }
    SectionLabel { text: "App activity" }
    StyledText {
        Layout.fillWidth: true
        text: "CPU time shows which apps were busy. It is not a measurement of watts or battery percentage per app."
        color: Colors.outline
        font.pixelSize: Motion.fontSize.body
        wrapMode: Text.Wrap
    }
    SettingGroup {
        Repeater {
            model: root.report.apps
            SettingRow {
                id: appRow
                required property var modelData
                required property int index
                first: index === 0
                last: index === root.report.apps.length - 1
                live: true
                label: modelData.name
                subtext: modelData.cpu.toFixed(1) + "% average CPU · 100% is one busy core"
                StyledText {
                    text: root.duration(appRow.modelData.seconds) + " CPU"
                    color: Colors.primary
                }
            }
        }
    }
    StyledText {
        Layout.fillWidth: true
        text: root.recording
            ? "Recording every 30 seconds · " + root.duration(root.report.coverage) + " of app activity in this period · kept for 30 days"
            : "The history recorder is not running. Saved battery history is still shown."
        color: root.recording ? Colors.outline : Colors.error
        font.pixelSize: Motion.fontSize.body
        wrapMode: Text.Wrap
    }
    StyledText {
        Layout.fillWidth: true
        visible: root.report.apps.length === 0
        text: "App history starts when recording is enabled. Use your laptop for a minute, then return here."
        color: Colors.outline
        wrapMode: Text.Wrap
    }
}
