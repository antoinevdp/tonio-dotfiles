//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

Scope {
    id: root

    property string cpuLabel: "  ▁▁▁▁  0%"
    property string memoryLabel: "  0.0G/0.0G"
    property string brightnessLabel: " 0%"
    property string musicArtUrl: ""
    property string swayncLabel: ""
    property var activeTrayMenuItem: null
    property var activeMusicPanel: null
    property real previousCpuTotal: 0
    property real previousCpuIdle: 0
    property var activePlayer: Mpris.players.values.find(player => player.playbackState !== MprisPlaybackState.Stopped) || Mpris.players.values[0] || null
    property var audioSink: Pipewire.defaultAudioSink
    property var battery: UPower.displayDevice
    property bool musicMenuOpen: false
    property var wiredDevice: Networking.devices.values.find(device => device.name === "enp10s0") || Networking.devices.values.find(device => device.connected)

    Colors { id: colors }

    function run(command) {
        commandRunner.exec(["sh", "-c", command]);
    }

    function closeMusicMenu() {
        musicMenuOpen = false;
        activeMusicPanel = null;
    }

    function playerArtUrl(player) {
        if (!player)
            return "";

        const metadata = player.metadata || {};
        const candidates = [
            player.trackArtUrl,
            metadata["mpris:artUrl"],
            metadata["xesam:artUrl"],
            metadata.artUrl,
            metadata.image,
        ];

        for (const candidate of candidates) {
            if (!candidate)
                continue;

            const value = typeof candidate === "string" ? candidate : (candidate.toString ? candidate.toString() : "");
            if (value && value !== "[object Object]")
                return value;
        }

        return "";
    }

    function truncate(text, length) {
        if (!text)
            return "-";
        return text.length > length ? text.slice(0, length - 3) + "..." : text;
    }

    function updateMusicArt(raw) {
        const nextUrl = raw.trim();
        musicArtUrl = nextUrl;
    }

    function barIcon(percent) {
        const icons = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"];
        return icons[Math.max(0, Math.min(icons.length - 1, Math.floor(percent / 13)))];
    }

    function audioIcon(percent) {
        if (percent <= 0)
            return "";
        if (percent < 35)
            return "";
        if (percent < 70)
            return "";
        return "";
    }

    function brightnessIcon(percent) {
        const icons = ["", "󰃜", "󰃛", "󰃞", "󰃝", "󰃟", "󰃠"];
        return icons[Math.max(0, Math.min(icons.length - 1, Math.floor(percent / 17)))];
    }

    function batteryIcon(percent) {
        const icons = ["", "", "", "", ""];
        return icons[Math.max(0, Math.min(icons.length - 1, Math.floor(percent / 25)))];
    }

    function activeWindowLabel() {
        const toplevel = Hyprland.activeToplevel;
        if (!toplevel)
            return "-";

        const ipc = toplevel.lastIpcObject || {};
        return truncate(ipc.class || toplevel.title || "-", 15);
    }

    function mprisText(player) {
        if (!player)
            return "";

        const icon = player.playbackState === MprisPlaybackState.Playing ? "⏸" : player.playbackState === MprisPlaybackState.Paused ? "▶" : "";
        const title = player.trackTitle || "";
        const artist = player.trackArtist || "";
        const label = [title, artist].filter(Boolean).join(" - ") || player.identity || "";
        return label ? truncate(icon + " " + label, 42) : "";
    }

    function volumeText() {
        if (!audioSink || !audioSink.audio)
            return "";

        const percent = Math.round(audioSink.audio.volume * 100);
        return audioSink.audio.muted ? "" : audioIcon(percent) + " " + percent + "%";
    }

    function networkText() {
        return wiredDevice && wiredDevice.connected ? "󰈀 LAN" : "󰖪";
    }

    function bluetoothText() {
        const adapter = Bluetooth.defaultAdapter;
        return adapter && adapter.enabled ? "" : "";
    }

    function batteryText() {
        if (!battery || !battery.ready || !battery.isPresent || battery.percentage <= 0)
            return "";

        const percent = Math.round(battery.percentage);
        const icon = battery.state === UPowerDeviceState.Charging ? "" : battery.state === UPowerDeviceState.FullyCharged ? "" : batteryIcon(percent);
        return icon + " " + percent + "%";
    }

    function updateCpu(raw) {
        const parts = raw.trim().split(/\s+/);
        if (parts.length < 2)
            return;

        const total = Number(parts[0]);
        const idle = Number(parts[1]);
        if (previousCpuTotal > 0) {
            const totalDelta = total - previousCpuTotal;
            const idleDelta = idle - previousCpuIdle;
            const usage = totalDelta > 0 ? Math.round((1 - idleDelta / totalDelta) * 100) : 0;
            const icon = barIcon(usage);
            cpuLabel = "  " + icon + icon + icon + icon + " " + String(usage).padStart(2, " ") + "%";
        }
        previousCpuTotal = total;
        previousCpuIdle = idle;
    }

    Process { id: commandRunner }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu / { idle=$5; total=0; for (i=2; i<=NF; i++) total += $i; print total, idle }' /proc/stat"]
        stdout: StdioCollector { onStreamFinished: root.updateCpu(this.text) }
    }

    Process {
        id: memoryProc
        command: ["sh", "-c", "free -m | awk '/Mem:/ { printf \"  %.1fG/%.1fG\", $3 / 1024, $2 / 1024 }'"]
        stdout: StdioCollector { onStreamFinished: root.memoryLabel = this.text.trim() || root.memoryLabel }
    }

    Process {
        id: brightnessProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const percent = Number(this.text.trim() || 0);
                root.brightnessLabel = root.brightnessIcon(percent) + " " + percent + "%";
            }
        }
    }

    Process {
        id: swayncProc
        command: ["sh", "-c", "count=$(swaync-client -c 2>/dev/null || printf 0); [ \"$count\" -gt 0 ] 2>/dev/null && printf '' || printf ''"]
        stdout: StdioCollector { onStreamFinished: root.swayncLabel = this.text.trim() || "" }
    }

    Process {
        id: musicArtProc
        command: ["sh", "-c", "playerctl metadata --format '{{mpris:artUrl}}' 2>/dev/null || true"]
        stdout: StdioCollector { onStreamFinished: root.updateMusicArt(this.text) }
    }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: cpuProc.exec(cpuProc.command) }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: memoryProc.exec(memoryProc.command) }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: brightnessProc.exec(brightnessProc.command) }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: swayncProc.exec(swayncProc.command) }
    Timer { interval: 1500; running: true; repeat: true; triggeredOnStart: true; onTriggered: musicArtProc.exec(musicArtProc.command) }

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property string command: ""
        property color contentColor: colors.foreground
        property int horizontalPadding: 11
        property int minimumWidth: 0
        signal pressed(var mouse)

        color: colors.background
        radius: 6
        implicitHeight: 34
        implicitWidth: Math.max(minimumWidth, labelText.implicitWidth + horizontalPadding * 2)

        Text {
            id: labelText
            anchors.centerIn: parent
            text: pill.label
            color: pill.contentColor
            font.family: "SpaceMono Nerd Font"
            font.pixelSize: 15
            font.weight: Font.Medium
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && pill.command.length > 0)
                    root.run(pill.command);
                pill.pressed(mouse);
            }
        }
    }

    component Segment: Item {
        id: segment
        property string label: ""
        property string command: ""

        visible: label.length > 0
        implicitWidth: labelText.implicitWidth
        implicitHeight: 20

        Text {
            id: labelText
            anchors.centerIn: parent
            text: segment.label
            color: colors.foreground
            font.family: "SpaceMono Nerd Font"
            font.pixelSize: 15
            font.weight: Font.Medium
        }

        MouseArea {
            anchors.fill: parent
            enabled: segment.command.length > 0
            cursorShape: Qt.PointingHandCursor
            onClicked: root.run(segment.command)
        }
    }

    component PlayerControlButton: Rectangle {
        id: button
        property string icon: ""
        property color baseColor: colors.background
        property color hoverColor: colors.lightBackground
        property color iconColor: colors.foreground
        signal pressed()

        color: buttonMouse.containsMouse && enabled ? hoverColor : baseColor
        radius: 8
        implicitWidth: 42
        implicitHeight: 36
        opacity: enabled ? 1 : 0.45

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: button.iconColor
            font.family: "SpaceMono Nerd Font"
            font.pixelSize: 16
            font.weight: Font.Medium
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.pressed()
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: panel
                required property var modelData

                screen: modelData
                color: "transparent"
                implicitHeight: 46

                anchors {
                    top: true
                    left: true
                    right: true
                }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 3
                    anchors.bottomMargin: 3

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Pill {
                            label: "󰣇"
                            command: "ghostty -e fish -c 'fastfetch; exec fish'"
                            horizontalPadding: 14
                        }

                        Pill {
                            label: root.activeWindowLabel()
                            horizontalPadding: 5
                            minimumWidth: 34
                        }

                        Rectangle {
                            color: colors.background
                            radius: 6
                            implicitHeight: 34
                            implicitWidth: workspaceRow.implicitWidth + 4

                            Row {
                                id: workspaceRow
                                anchors.centerIn: parent
                                spacing: 0

                                Repeater {
                                    model: Hyprland.workspaces

                                    Rectangle {
                                        required property var modelData
                                        property bool hovered: false

                                        visible: modelData.id > 0
                                        width: visible ? workspaceLabel.implicitWidth + 18 : 0
                                        height: 30
                                        radius: 5
                                        color: "transparent"
                                        border.width: hovered ? 1 : 0
                                        border.color: colors.textActive

                                        Text {
                                            id: workspaceLabel
                                            anchors.centerIn: parent
                                            text: modelData.name + ": " + (modelData.active ? "" : "")
                                            color: modelData.active ? colors.textActive : colors.foreground
                                            font.family: "SpaceMono Nerd Font"
                                            font.pixelSize: 15
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: parent.hovered = true
                                            onExited: parent.hovered = false
                                            onClicked: modelData.activate()
                                        }
                                    }
                                }
                            }
                        }

                        Pill {
                            id: musicPill
                            visible: root.mprisText(root.activePlayer).length > 0
                            label: root.mprisText(root.activePlayer)
                            onPressed: mouse => {
                                if (mouse.button !== Qt.LeftButton)
                                    return;

                                if (root.musicMenuOpen && root.activeMusicPanel === panel)
                                    root.closeMusicMenu();
                                else {
                                    root.activeMusicPanel = panel;
                                    root.musicMenuOpen = true;
                                }
                            }
                        }

                        PopupWindow {
                            id: musicPopup
                            anchor.item: musicPill
                            anchor.rect.x: 0
                            anchor.rect.y: musicPill.height + 6
                            anchor.rect.width: Math.max(1, musicPill.width)
                            anchor.rect.height: 1
                            visible: root.musicMenuOpen && root.activeMusicPanel === panel && root.activePlayer !== null
                            grabFocus: true
                            color: "transparent"
                            implicitWidth: 350
                            implicitHeight: 154

                            onVisibleChanged: {
                                if (!visible && root.activeMusicPanel === panel)
                                    root.closeMusicMenu();
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: colors.secondBackground
                                border.color: colors.borders
                                border.width: 1
                                radius: 12

                                Row {
                                    id: musicContentRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 14
                                    height: Math.max(artFrame.height, detailsColumn.implicitHeight)

                                    Item {
                                        width: artFrame.width
                                        height: musicContentRow.height

                                        Rectangle {
                                            id: artFrame
                                            property string artUrl: root.musicArtUrl || root.playerArtUrl(root.activePlayer)
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 110
                                            height: 110
                                            radius: 12
                                            color: colors.lightBackground
                                            clip: true

                                            Image {
                                                id: artImage
                                                anchors.fill: parent
                                                source: artFrame.artUrl
                                                sourceSize.width: width
                                                sourceSize.height: height
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                cache: false
                                                visible: status === Image.Ready || status === Image.Loading

                                                onStatusChanged: {
                                                    if (status === Image.Error)
                                                        console.warn("music art failed to load", artFrame.artUrl);
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: artFrame.artUrl.length === 0 || artImage.status === Image.Error || artImage.status === Image.Null
                                                text: ""
                                                color: colors.outline
                                                font.family: "SpaceMono Nerd Font"
                                                font.pixelSize: 34
                                            }
                                        }
                                    }

                                    Column {
                                        id: detailsColumn
                                        width: musicContentRow.width - artFrame.width - musicContentRow.spacing
                                        spacing: 7

                                        Text {
                                            width: parent.width
                                            text: root.activePlayer
                                                ? (root.activePlayer.trackTitle || root.activePlayer.identity || "Nothing playing")
                                                : "Nothing playing"
                                            color: colors.foreground
                                            font.family: "SpaceMono Nerd Font"
                                            font.pixelSize: 15
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: root.activePlayer
                                                ? (root.activePlayer.trackArtist || root.activePlayer.trackAlbumArtist || "Unknown artist")
                                                : ""
                                            color: colors.textActive
                                            font.family: "SpaceMono Nerd Font"
                                            font.pixelSize: 14
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: root.activePlayer
                                                ? (root.activePlayer.trackAlbum || root.activePlayer.identity || "")
                                                : ""
                                            color: colors.outline
                                            font.family: "SpaceMono Nerd Font"
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                        }

                                        Item {
                                            width: 1
                                            height: 4
                                        }

                                        Row {
                                            spacing: 8

                                            PlayerControlButton {
                                                icon: ""
                                                enabled: root.activePlayer && root.activePlayer.canGoPrevious
                                                onPressed: root.activePlayer.previous()
                                            }

                                            PlayerControlButton {
                                                icon: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? "" : ""
                                                enabled: root.activePlayer && root.activePlayer.canTogglePlaying
                                                implicitWidth: 56
                                                baseColor: colors.primary
                                                hoverColor: colors.textActive
                                                iconColor: colors.background
                                                onPressed: root.activePlayer.togglePlaying()
                                            }

                                            PlayerControlButton {
                                                icon: ""
                                                enabled: root.activePlayer && root.activePlayer.canGoNext
                                                onPressed: root.activePlayer.next()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Pill {
                        label: Qt.formatDateTime(clock.date, "ddd,dd - HH:mm")
                        anchors.centerIn: parent
                        command: "gnome-calendar"
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Rectangle {
                            id: trayContainer
                            color: colors.background
                            radius: 6
                            visible: SystemTray.items.values.length > 0
                            implicitHeight: 34
                            implicitWidth: trayRow.implicitWidth + 22

                            Row {
                                id: trayRow
                                anchors.centerIn: parent
                                spacing: 10

                                Repeater {
                                    model: SystemTray.items

                                    Item {
                                        id: trayItem
                                        required property var modelData
                                        property bool menuOpen: false
                                        width: 14
                                        height: 20

                                        QsMenuOpener {
                                            id: trayMenuOpener
                                            menu: modelData.menu
                                        }

                                        HyprlandFocusGrab {
                                            windows: trayMenuPopup.activeSubmenuWindow ? [trayMenuPopup, trayMenuPopup.activeSubmenuWindow] : [trayMenuPopup]
                                            active: trayItem.menuOpen
                                            onCleared: {
                                                trayItem.menuOpen = false;
                                                if (root.activeTrayMenuItem === trayItem)
                                                    root.activeTrayMenuItem = null;
                                            }
                                        }

                                        PanelWindow {
                                            id: trayMenuPopup
                                            property var activeSubmenuEntry: null
                                            property var activeSubmenuWindow: null
                                            visible: trayItem.menuOpen && modelData.hasMenu
                                            color: "transparent"
                                            exclusiveZone: -1
                                            WlrLayershell.layer: WlrLayer.Overlay
                                            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                                            anchors {
                                                top: true
                                                right: true
                                            }
                                            margins {
                                                top: panel.implicitHeight + 4
                                                right: Math.max(10, panel.contentItem.width - trayItem.mapToItem(panel.contentItem, trayItem.width, 0).x)
                                            }
                                            implicitWidth: 240
                                            implicitHeight: trayMenuColumn.implicitHeight + 12

                                            onVisibleChanged: {
                                                if (!visible && activeSubmenuEntry) {
                                                    activeSubmenuEntry.submenuOpen = false;
                                                    activeSubmenuEntry = null;
                                                }
                                                if (!visible)
                                                    activeSubmenuWindow = null;
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                color: colors.secondBackground
                                                border.color: colors.borders
                                                border.width: 1
                                                radius: 10
                                                clip: true

                                                Column {
                                                    id: trayMenuColumn
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 2

                                                    Repeater {
                                                        model: trayMenuOpener.children.values

                                                        delegate: Item {
                                                            id: trayMenuEntry
                                                            required property QsMenuEntry modelData
                                                            property bool submenuOpen: false
                                                            width: trayMenuColumn.width
                                                            height: modelData.isSeparator ? 9 : 30

                                                            QsMenuOpener {
                                                                id: submenuOpener
                                                                menu: trayMenuEntry.modelData
                                                            }

                                                            Rectangle {
                                                                visible: trayMenuEntry.modelData.isSeparator
                                                                anchors.centerIn: parent
                                                                width: parent.width - 8
                                                                height: 1
                                                                color: colors.borders
                                                            }

                                                            Rectangle {
                                                                visible: !trayMenuEntry.modelData.isSeparator
                                                                anchors.fill: parent
                                                                radius: 6
                                                                color: entryMouse.containsMouse && trayMenuEntry.modelData.enabled ? colors.lightBackground : "transparent"

                                                                Item {
                                                                    anchors.fill: parent
                                                                    anchors.leftMargin: 10
                                                                    anchors.rightMargin: 10

                                                                    Text {
                                                                        id: checkText
                                                                        anchors.left: parent.left
                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                        width: visible ? implicitWidth : 0
                                                                        text: trayMenuEntry.modelData.buttonType === QsMenuButtonType.RadioButton
                                                                            ? (trayMenuEntry.modelData.checkState === Qt.Checked ? "◉" : "○")
                                                                            : (trayMenuEntry.modelData.buttonType === QsMenuButtonType.CheckBox
                                                                                ? (trayMenuEntry.modelData.checkState === Qt.PartiallyChecked ? "-" : (trayMenuEntry.modelData.checkState === Qt.Checked ? "✓" : "☐"))
                                                                                : "")
                                                                        visible: trayMenuEntry.modelData.buttonType !== QsMenuButtonType.None
                                                                        color: colors.textActive
                                                                        font.family: "SpaceMono Nerd Font"
                                                                        font.pixelSize: 13
                                                                    }

                                                                    Image {
                                                                        id: entryIcon
                                                                        anchors.left: checkText.right
                                                                        anchors.leftMargin: checkText.visible ? 8 : 0
                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                        source: trayMenuEntry.modelData.icon || ""
                                                                        sourceSize.width: 16
                                                                        sourceSize.height: 16
                                                                        width: source.length > 0 ? 16 : 0
                                                                        height: source.length > 0 ? 16 : 0
                                                                    }

                                                                    HoverMarqueeText {
                                                                        anchors.left: entryIcon.right
                                                                        anchors.leftMargin: entryIcon.width > 0 ? 8 : (checkText.visible ? 8 : 0)
                                                                        anchors.right: submenuArrow.visible ? submenuArrow.left : parent.right
                                                                        anchors.rightMargin: submenuArrow.visible ? 12 : 0
                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                        text: trayMenuEntry.modelData.text || ""
                                                                        textColor: trayMenuEntry.modelData.enabled
                                                                            ? (entryMouse.containsMouse ? colors.textActive : colors.foreground)
                                                                            : colors.outline
                                                                        fontFamily: "SpaceMono Nerd Font"
                                                                        pixelSize: 14
                                                                        hovered: entryMouse.containsMouse
                                                                    }

                                                                    Text {
                                                                        id: submenuArrow
                                                                        anchors.right: parent.right
                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                        text: ">"
                                                                        visible: trayMenuEntry.modelData.hasChildren
                                                                        color: entryMouse.containsMouse ? colors.textActive : colors.outline
                                                                        font.family: "SpaceMono Nerd Font"
                                                                        font.pixelSize: 14
                                                                    }
                                                                }

                                                                MouseArea {
                                                                    id: entryMouse
                                                                    anchors.fill: parent
                                                                    hoverEnabled: true
                                                                    enabled: !trayMenuEntry.modelData.isSeparator
                                                                    cursorShape: trayMenuEntry.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                                    onEntered: {
                                                                        if (trayMenuEntry.modelData.hasChildren) {
                                                                            if (trayMenuPopup.activeSubmenuEntry && trayMenuPopup.activeSubmenuEntry !== trayMenuEntry)
                                                                                trayMenuPopup.activeSubmenuEntry.submenuOpen = false;

                                                                            trayMenuPopup.activeSubmenuEntry = trayMenuEntry;
                                                                            trayMenuEntry.submenuOpen = true;
                                                                            trayMenuPopup.activeSubmenuWindow = submenuPopup;
                                                                        } else if (trayMenuPopup.activeSubmenuEntry) {
                                                                            trayMenuPopup.activeSubmenuEntry.submenuOpen = false;
                                                                            trayMenuPopup.activeSubmenuEntry = null;
                                                                            trayMenuPopup.activeSubmenuWindow = null;
                                                                        }
                                                                    }
                                                                    onClicked: {
                                                                        if (trayMenuEntry.modelData.enabled && !trayMenuEntry.modelData.hasChildren) {
                                                                            trayMenuEntry.modelData.triggered();
                                                                            trayItem.menuOpen = false;
                                                                            trayMenuEntry.submenuOpen = false;
                                                                            trayMenuPopup.activeSubmenuEntry = null;
                                                                            trayMenuPopup.activeSubmenuWindow = null;
                                                                            if (root.activeTrayMenuItem === trayItem)
                                                                                root.activeTrayMenuItem = null;
                                                                        }
                                                                    }
                                                                }
                                                            }

                                                            PanelWindow {
                                                                id: submenuPopup
                                                                visible: trayMenuEntry.submenuOpen && trayMenuEntry.modelData.hasChildren
                                                                color: "transparent"
                                                                screen: panel.screen
                                                                exclusiveZone: -1
                                                                WlrLayershell.layer: WlrLayer.Overlay
                                                                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                                                                anchors {
                                                                    top: true
                                                                    left: true
                                                                }
                                                                margins {
                                                                    top: Math.max(0, trayMenuPopup.margins.top + 6 + trayMenuEntry.y)
                                                                    left: Math.max(10, (screen?.width || 0) - trayMenuPopup.margins.right + 6)
                                                                }
                                                                implicitWidth: 240
                                                                implicitHeight: submenuColumn.implicitHeight + 12

                                                                onVisibleChanged: {
                                                                    if (!visible && trayMenuPopup.activeSubmenuWindow === submenuPopup)
                                                                        trayMenuPopup.activeSubmenuWindow = null;
                                                                }

                                                                Rectangle {
                                                                    anchors.fill: parent
                                                                    color: colors.secondBackground
                                                                    border.color: colors.borders
                                                                    border.width: 1
                                                                    radius: 10
                                                                    clip: true

                                                                    Column {
                                                                        id: submenuColumn
                                                                        anchors.fill: parent
                                                                        anchors.margins: 6
                                                                        spacing: 2

                                                                        Repeater {
                                                                            model: submenuOpener.children.values

                                                                            delegate: Item {
                                                                                id: submenuEntry
                                                                                required property QsMenuEntry modelData
                                                                                width: submenuColumn.width
                                                                                height: modelData.isSeparator ? 9 : 30

                                                                                Rectangle {
                                                                                    visible: submenuEntry.modelData.isSeparator
                                                                                    anchors.centerIn: parent
                                                                                    width: parent.width - 8
                                                                                    height: 1
                                                                                    color: colors.borders
                                                                                }

                                                                                Rectangle {
                                                                                    visible: !submenuEntry.modelData.isSeparator
                                                                                    anchors.fill: parent
                                                                                    radius: 6
                                                                                    color: submenuMouse.containsMouse && submenuEntry.modelData.enabled ? colors.lightBackground : "transparent"

                                                                                    HoverMarqueeText {
                                                                                        anchors.left: parent.left
                                                                                        anchors.leftMargin: 10
                                                                                        anchors.right: parent.right
                                                                                        anchors.rightMargin: 10
                                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                                        text: submenuEntry.modelData.text || ""
                                                                                        textColor: submenuEntry.modelData.enabled
                                                                                            ? (submenuMouse.containsMouse ? colors.textActive : colors.foreground)
                                                                                            : colors.outline
                                                                                        fontFamily: "SpaceMono Nerd Font"
                                                                                        pixelSize: 14
                                                                                        hovered: submenuMouse.containsMouse
                                                                                    }

                                                                                    MouseArea {
                                                                                        id: submenuMouse
                                                                                        anchors.fill: parent
                                                                                        hoverEnabled: true
                                                                                        enabled: !submenuEntry.modelData.isSeparator
                                                                                        cursorShape: submenuEntry.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                                                        onClicked: {
                                                                                            if (submenuEntry.modelData.enabled && !submenuEntry.modelData.hasChildren) {
                                                                                                submenuEntry.modelData.triggered();
                                                                                                trayMenuEntry.submenuOpen = false;
                                                                                                trayItem.menuOpen = false;
                                                                                                if (root.activeTrayMenuItem === trayItem)
                                                                                                    root.activeTrayMenuItem = null;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }

                                                            Connections {
                                                                target: trayItem

                                                                function onMenuOpenChanged() {
                                                                    if (!trayItem.menuOpen)
                                                                        trayMenuEntry.submenuOpen = false;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Image {
                                            anchors.centerIn: parent
                                            source: modelData.icon
                                            sourceSize.width: 14
                                            sourceSize.height: 14
                                            width: 14
                                            height: 14
                                        }

                                        MouseArea {
                                            id: trayMouseArea
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                            cursorShape: Qt.PointingHandCursor
                                            function showMenu() {
                                                if (!modelData.hasMenu)
                                                    return;

                                                if (root.activeTrayMenuItem && root.activeTrayMenuItem !== trayItem)
                                                    root.activeTrayMenuItem.menuOpen = false;

                                                if (trayItem.menuOpen) {
                                                    trayItem.menuOpen = false;
                                                    if (root.activeTrayMenuItem === trayItem)
                                                        root.activeTrayMenuItem = null;
                                                } else {
                                                    trayItem.menuOpen = true;
                                                    root.activeTrayMenuItem = trayItem;
                                                }
                                            }
                                            onClicked: mouse => {
                                                if (mouse.button === Qt.LeftButton) {
                                                    if (modelData.onlyMenu)
                                                        showMenu();
                                                    else
                                                        modelData.activate();
                                                }
                                                else if (mouse.button === Qt.MiddleButton)
                                                    modelData.secondaryActivate();
                                                else if (modelData.hasMenu)
                                                    showMenu();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        CodexUsage {
                            palette: colors
                            onRunCommand: command => root.run(command)
                        }

                        Pill { label: root.cpuLabel; command: "ghostty -e btm" }
                        Pill { label: root.memoryLabel; command: "ghostty -e btm" }

                        Rectangle {
                            color: colors.background
                            radius: 6
                            implicitHeight: 34
                            implicitWidth: systemRow.implicitWidth + 22

                            Row {
                                id: systemRow
                                anchors.centerIn: parent
                                spacing: 10

                                Segment { label: root.volumeText(); command: "pavucontrol" }
                                Segment { label: root.brightnessLabel }
                                Segment { label: root.networkText(); command: "XDG_CURRENT_DESKTOP='gnome' gnome-control-center network" }
                                Segment { label: root.bluetoothText(); command: "blueman-manager" }
                                Segment { label: root.batteryText(); command: "wlogout" }
                            }
                        }

                        Pill {
                            label: root.swayncLabel
                            command: "swaync-client -t -sw"
                            horizontalPadding: 13
                            onPressed: mouse => {
                                if (mouse.button === Qt.RightButton)
                                    root.run("swaync-client -d -sw");
                            }
                        }
                    }
                }
            }
        }
    }
}
