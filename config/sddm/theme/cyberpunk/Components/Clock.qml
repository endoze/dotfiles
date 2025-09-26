import QtQuick 2.15

Item {
  anchors.fill: parent

  // Date at top center
  Text {
    anchors {
      horizontalCenter: parent.horizontalCenter
      top: parent.top
      topMargin: parent.height * 0.02
    }
    text: Qt.formatDateTime(new Date(), "dddd, d MMMM yyyy")
    color: "#e6e6e6"
    font.family: config.Font
    font.pixelSize: 20
    font.bold: true
  }

  // Time in center
  Text {
    id: timeText
    anchors.centerIn: parent
    text: Qt.formatTime(new Date(), "hh:mm:ss AP")
    color: "#ffffff"
    font.family: config.Font
    font.pixelSize: 48
    font.bold: true

    Timer {
      interval: 1000
      running: true
      repeat: true
      onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm:ss AP")
    }
  }
}
