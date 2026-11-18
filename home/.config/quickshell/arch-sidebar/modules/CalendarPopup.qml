import QtQuick
import Quickshell
import "Jalali.js" as Jalali

// Calendar popup under the clock (click the date on the bar): month grid with week numbers, today highlighted,
// ‹ › to change month (or scroll), Today, the full date in Gregorian and Persian. Escape or a click on the
// clock closes it.
PanelWindow {
    id: win

    property bool open: false
    property int barHeight: 28
    property int gap: 10
    property date shown: new Date()           // any day of the month on display
    property date today: new Date()

    visible: open
    anchors { top: true; right: true }
    margins { top: barHeight + gap; right: gap }
    implicitWidth: 330
    implicitHeight: box.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"

    onOpenChanged: if (open) { today = new Date(); shown = new Date(); box.forceActiveFocus() }

    function addMonths(n) { shown = new Date(shown.getFullYear(), shown.getMonth() + n, 1) }
    function sameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate() }
    // ISO week number
    function week(d) {
        const t = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 3 - (d.getDay() + 6) % 7)
        const w1 = new Date(t.getFullYear(), 0, 4)
        return 1 + Math.round(((t - w1) / 86400000 - 3 + (w1.getDay() + 6) % 7) / 7)
    }
    // 6 rows × 7 days, Monday first
    readonly property var days: {
        const first = new Date(shown.getFullYear(), shown.getMonth(), 1)
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - (first.getDay() + 6) % 7)
        const out = []
        for (let i = 0; i < 42; i++) out.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i))
        return out
    }

    // keep the clock fresh while open
    Timer { interval: 30000; running: win.open; repeat: true; onTriggered: win.today = new Date() }

    Rectangle {
        id: box
        width: parent.width
        implicitHeight: col.implicitHeight + 32
        radius: 14
        color: "#1a1b26"
        border.width: 1
        border.color: "#414868"
        focus: true
        Keys.onEscapePressed: win.open = false
        Keys.onLeftPressed: win.addMonths(-1)
        Keys.onRightPressed: win.addMonths(1)

        WheelHandler { onWheel: e => win.addMonths(e.angleDelta.y > 0 ? -1 : 1) }

        Column {
            id: col
            x: 16; y: 16
            width: parent.width - 32
            spacing: 10

            // today, big
            Column {
                width: parent.width
                spacing: 2
                Text { text: Qt.formatDateTime(win.today, "dddd"); color: "#7aa2f7"; font.pixelSize: 12; font.bold: true }
                Text { text: Qt.formatDateTime(win.today, "d MMMM yyyy"); color: "#c0caf5"; font.pixelSize: 20; font.bold: true }
                Text {
                    text: Jalali.format(win.today) + "   ·   " + Qt.formatDateTime(win.today, "HH:mm")
                    color: "#a9b1d6"; font.pixelSize: 12; font.family: "Vazirmatn"
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#414868" }

            // month header
            Item {
                width: parent.width
                height: 30
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(win.shown, "MMMM yyyy")
                    color: "#c0caf5"; font.pixelSize: 14; font.bold: true
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: [{ t: "‹", d: -1 }, { t: "Today", d: 0 }, { t: "›", d: 1 }]
                        delegate: Rectangle {
                            width: modelData.d === 0 ? 52 : 28; height: 26; radius: 7
                            color: nm.containsMouse ? "#2f3549" : "#24283b"
                            border.width: 1; border.color: "#414868"
                            Text { anchors.centerIn: parent; text: modelData.t; color: "#c0caf5"; font.pixelSize: modelData.d === 0 ? 10 : 15 }
                            MouseArea {
                                id: nm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.d === 0 ? (win.shown = new Date()) : win.addMonths(modelData.d)
                            }
                        }
                    }
                }
            }

            // grid: week number + 7 days
            Grid {
                id: grid
                columns: 8
                columnSpacing: 2
                rowSpacing: 2
                readonly property real cell: (col.width - 7 * columnSpacing) / 8

                Repeater {
                    model: ["", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    delegate: Text {
                        width: grid.cell; height: 22
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: index >= 6 ? "#bb9af7" : "#565f89"; font.pixelSize: 10; font.bold: true
                    }
                }
                Repeater {
                    model: 48
                    delegate: Rectangle {
                        readonly property bool wk: index % 8 === 0
                        readonly property var day: wk ? win.days[(index / 8) * 7] : win.days[Math.floor(index / 8) * 7 + index % 8 - 1]
                        readonly property bool inMonth: day.getMonth() === win.shown.getMonth()
                        readonly property bool isToday: !wk && win.sameDay(day, win.today)
                        width: grid.cell; height: 32; radius: 8
                        color: isToday ? "#7aa2f7" : (dm.containsMouse && !wk ? "#24283b" : "transparent")
                        Text {
                            anchors.centerIn: parent
                            text: parent.wk ? win.week(parent.day) : parent.day.getDate()
                            font.pixelSize: parent.wk ? 9 : 12
                            font.bold: parent.isToday
                            color: parent.wk ? "#414868"
                                 : parent.isToday ? "#1a1b26"
                                 : !parent.inMonth ? "#3b4261"
                                 : index % 8 >= 6 ? "#bb9af7" : "#c0caf5"
                        }
                        MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "week " + win.week(win.today) + "  ·  scroll or ← → to change month  ·  Esc closes"
                color: "#414868"; font.pixelSize: 9
            }
        }
    }
}
