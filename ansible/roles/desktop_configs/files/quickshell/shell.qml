import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    id: root

    title: "Calendar widget"
    color: "#2e3440"

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    function shiftMonth(delta) {
        let m = viewMonth + delta
        let y = viewYear
        if (m < 0) {
            m = 11
            y -= 1
        } else if (m > 11) {
            m = 0
            y += 1
        }
        viewMonth = m
        viewYear = y
    }

    implicitWidth: content.implicitWidth + 28
    implicitHeight: content.implicitHeight + 28
    visible: false

    IpcHandler {
        target: "calendar"

        function toggle(): void {
            if (!root.visible) {
                root.today = new Date()
                root.viewYear = root.today.getFullYear()
                root.viewMonth = root.today.getMonth()
            }
            root.visible = !root.visible
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: "#88c0d0"
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(-1)
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().standaloneMonthName(root.viewMonth) + " " + root.viewYear
                font.pixelSize: 16
                font.bold: true
                color: "#eceff4"
            }

            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: "#88c0d0"
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(1)
                }
            }
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 7
            columnSpacing: 4
            rowSpacing: 4

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: Text {
                    Layout.preferredWidth: 30
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: "#88c0d0"
                    font.bold: true
                    font.pixelSize: 13
                }
            }

            Repeater {
                model: {
                    const firstOfMonth = new Date(root.viewYear, root.viewMonth, 1)
                    const leadingBlanks = (firstOfMonth.getDay() + 6) % 7
                    const daysInMonth = new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
                    const cells = []
                    for (let i = 0; i < leadingBlanks; i++) cells.push(0)
                    for (let d = 1; d <= daysInMonth; d++) cells.push(d)
                    while (cells.length < 42) cells.push(0)
                    return cells
                }
                delegate: Rectangle {
                    property bool isToday: modelData === root.today.getDate()
                        && root.viewMonth === root.today.getMonth()
                        && root.viewYear === root.today.getFullYear()

                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 26
                    radius: 4
                    color: isToday ? "#88c0d0" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData === 0 ? "" : modelData
                        color: isToday ? "#2e3440" : "#eceff4"
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
