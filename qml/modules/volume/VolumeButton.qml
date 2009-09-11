import Qt 4.6
import WesControl 1.0

Item {
    height: 80
    width: 90
    Image {
        id: volumeButton
        height: 50
        source: "images/speaker.png"
        smooth: true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.rightMargin: 150
        fillMode: "PreserveAspectFit"
        y: 5
    }
    Volume {
        id: volumeController
    }
    Text {
        id: volumeText
        color: "#CCCCCC"
        font.family: "Myriad Pro"
        font.pointSize: 20
        text: volumeController.volume.round
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 25
        anchors.rightMargin: 10
        opacity: (volumeController.volume >= 0 && volumeController.volume <= 1) ? 1 : 0
    }
}
