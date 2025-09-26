import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
  id: passwordField
  focus: true
  selectByMouse: true
  placeholderText: ""
  echoMode: TextInput.Password
  passwordCharacter: "●"
  passwordMaskDelay: config.PasswordShowLastLetter
  selectionColor: "#7aa2f7"
  cursorDelegate: Rectangle {
    width: 0
    visible: false
  }
  renderType: Text.NativeRendering
  font.family: "Cantarell"  // Proportional font instead of monospace
  font.pixelSize: 16
  font.bold: false
  font.italic: false
  font.letterSpacing: 0
  color: text ? "#1a1b26" : "#565f89"
  horizontalAlignment: Text.AlignHCenter
  cursorVisible: false
  verticalAlignment: Text.AlignVCenter
  // leftPadding: -7
  // rightPadding: 7
  // topPadding: 2
  // bottomPadding: -2
  background: Rectangle {
    id: passFieldBackground
    radius: height / 2  // Pill shape
    color: "#ffffff"
    opacity: 1.0
  }
  states: [
    State {
      name: "focused"
      when: passwordField.activeFocus
      PropertyChanges {
        passFieldBackground.color: "#ffffff"
      }
    },
    State {
      name: "hovered"
      when: passwordField.hovered
      PropertyChanges {
        passFieldBackground.color: "#ffffff"
      }
    }
  ]
  transitions: Transition {
    PropertyAnimation {
      properties: "color"
      duration: 300
    }
  }
}
