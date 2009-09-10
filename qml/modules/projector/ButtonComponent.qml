import Qt 4.6
Item {
    id: ButtonComponent
    property alias imageSource: image.source
    property alias imageWidth: image.width
    property alias imageHeight: image.height
    property alias text: displayText.text
    signal clicked
    height: 77
    width: 380
    opacity: Behavior {
        NumberAnimation {
            duration: 200
        }
    }
    Rectangle {
        radius: 20
        pen.color: "white"
        opacity: 0.5
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { id: gradientStop1; position: 0.0; color: "#666666" }
            GradientStop { id: gradientStop2; position: 1.0; color: "#000000" }
        }
    }
    Item {
        id: buttonContent
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        Image {
            id: image
            smooth: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
        }
        Text {
            id: displayText
            font.pointSize: 40
            color: "white"
            font.family: "Myriad Pro"
            font.bold: true
            anchors.left: image.right
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseRegion {
        id: mouseRegion
        anchors.fill: parent
        onClicked: {
            ButtonComponent.clicked();
        }
    }

    states: [
        State {
            name: "pressed"
            when: mouseRegion.pressed
            PropertyChanges {
                target: gradientStop1
                color: "#000000"
            }
            PropertyChanges {
                target: gradientStop2
                color: "#666666"
            }
            PropertyChanges {
                target: buttonContent
                scale: 0.95
            }
        }
    ]
    transitions: [
        Transition {
            ColorAnimation {
                property: "color"
                duration: 90
            }
            NumberAnimation {
                property: "scale"
                duration: 90
            }
            NumberAnimation {
                property: "opacity"
                duration: 200
            }
        }
    ]
}
