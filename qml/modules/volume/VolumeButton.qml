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
    Text {
        id: volumeText
        color: "#CCCCCC"
        font.family: "Myriad Pro"
        font.pointSize: 20
        text: Math.round(volumecontroller.volume * 100)
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 25
        anchors.rightMargin: 10
        opacity: (volumecontroller.volume >= 0 && volumecontroller.volume <= 1) ? 1 : 0
    }
}
