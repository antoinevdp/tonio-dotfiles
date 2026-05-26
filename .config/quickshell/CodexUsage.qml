import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    property var palette
    property string command: "~/.config/quickshell/scripts/codex-usage.sh"
    property string status: "loading"
    property string resetAt: ""
    property string weeklyResetAt: ""
    property string planType: ""
    property string creditsBalance: ""
    property bool hasCredits: false
    property int fiveHourUsed: -1
    property int weeklyUsed: -1

    signal runCommand(string command)

    color: palette ? palette.background : "#101418"
    radius: 6
    implicitHeight: 34
    implicitWidth: labelText.implicitWidth + 22

    function usageIcon(percent) {
        if (percent < 0)
            return "";
        if (percent >= 90)
            return "󰀦";
        if (percent >= 70)
            return "󰀨";
        return "󰚩";
    }

    function usageText(value) {
        return value >= 0 ? value + "%" : "--";
    }

    function update(raw) {
        const text = raw.trim();
        if (!text.length)
            return;

        try {
            const data = JSON.parse(text);
            status = data.status || "ok";
            fiveHourUsed = Number.isFinite(Number(data.five_hour_used_percent)) ? Math.round(Number(data.five_hour_used_percent)) : -1;
            weeklyUsed = Number.isFinite(Number(data.weekly_used_percent)) ? Math.round(Number(data.weekly_used_percent)) : -1;
            resetAt = data.reset_at || "";
            weeklyResetAt = data.weekly_reset_at || "";
            planType = data.plan_type || "";
            hasCredits = Boolean(data.has_credits);
            creditsBalance = data.credits_balance || "";
        } catch (error) {
            status = "error";
            fiveHourUsed = -1;
            weeklyUsed = -1;
            resetAt = "";
            weeklyResetAt = "";
            planType = "";
            hasCredits = false;
            creditsBalance = "";
        }
    }

    Process {
        id: usageProc
        command: ["sh", "-c", root.command]
        stdout: StdioCollector { onStreamFinished: root.update(this.text) }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: usageProc.exec(usageProc.command)
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.usageIcon(Math.max(root.fiveHourUsed, root.weeklyUsed)) + " 5h " + root.usageText(root.fiveHourUsed) + "  W " + root.usageText(root.weeklyUsed)
        color: root.status === "error" ? (root.palette ? root.palette.tertiary : "#d6bee5") : (root.palette ? root.palette.foreground : "#e1e2e8")
        font.family: "SpaceMono Nerd Font"
        font.pixelSize: 15
        font.weight: Font.Medium
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                usageProc.exec(usageProc.command);
                return;
            }

            root.runCommand("ghostty -e sh -c 'printf \"Codex usage\\n\\n5h: %s\\n5h reset: %s\\nWeekly: %s\\nWeekly reset: %s\\nPlan: %s\\nCredits: %s\\nStatus: %s\\n\\nData source: ~/.cache/quickshell/codex-usage.json\\n\" \"" + root.usageText(root.fiveHourUsed) + "\" \"" + (root.resetAt || "unknown") + "\" \"" + root.usageText(root.weeklyUsed) + "\" \"" + (root.weeklyResetAt || "unknown") + "\" \"" + (root.planType || "unknown") + "\" \"" + (root.hasCredits ? root.creditsBalance : "none") + "\" \"" + root.status + "\"; read -r _'");
        }
    }
}
