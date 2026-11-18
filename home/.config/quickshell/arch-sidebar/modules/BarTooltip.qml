import QtQuick
import Quickshell
import Quickshell.Io

// Tooltip under a dwm bar item (Wi-Fi, volume, battery…). dwm reports the hovered status block
// (dwm-statushover → ipc "tooltip show <item> <x> <y> <width>"); the text comes from dwm-bartip.
PanelWindow {
    id: win

    property string item: ""
    property int bx: 0            // block left edge / width / bar bottom, absolute screen coordinates
    property int bw: 0
    property int by: 0
    property var lines: []
    property bool wanted: false   // hovering
    property var scr: Quickshell.screens.length ? Quickshell.screens[0] : null

    function show(name, x, y, w) {
        visible = false
        item = name; bx = x; by = y; bw = w
        // the screen the item is on
        for (const s of Quickshell.screens)
            if (x >= s.x && x < s.x + s.width) { scr = s; break }
        wanted = true
        textP.running = false; textP.running = true
        delay.restart()
    }
    function hide() { wanted = false; delay.stop(); visible = false }

    screen: scr
    visible: false
    anchors { top: true; left: true }
    margins {
        top: Math.max(0, win.by - (win.scr ? win.scr.y : 0) + 6)
        // centred under the item, kept on the screen
        left: Math.max(8, Math.min((win.scr ? win.scr.width : 1920) - implicitWidth - 8,
                                   win.bx - (win.scr ? win.scr.x : 0) + win.bw / 2 - implicitWidth / 2))
    }
    implicitWidth: Math.min(420, Math.max(160, body.implicitWidth + 28))
    implicitHeight: body.implicitHeight + 20
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    Process {
        id: textP
        command: ["dwm-bartip", win.item]
        stdout: StdioCollector { onStreamFinished: win.lines = this.text.trim().split("\n") }
    }
    // a short delay so moving across the bar doesn't flash tooltips
    Timer { id: delay; interval: 280; onTriggered: if (win.wanted && win.lines.length) win.visible = true }
    // live values while it is shown (volume, signal…)
    Timer { interval: 2000; running: win.visible; repeat: true; onTriggered: if (!textP.running) textP.running = true }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#1a1b26"
        border.width: 1
        border.color: "#414868"

        Column {
            id: body
            x: 14; y: 10
            spacing: 3
            Repeater {
                model: win.lines
                delegate: Text {
                    readonly property bool first: index === 0
                    readonly property bool hint: index === win.lines.length - 1 && win.lines.length > 1
                    text: modelData
                    color: first ? "#c0caf5" : hint ? "#565f89" : "#a9b1d6"
                    font.pixelSize: first ? 13 : hint ? 10 : 11
                    font.bold: first
                    topPadding: hint ? 4 : 0
                }
            }
        }
    }
}
