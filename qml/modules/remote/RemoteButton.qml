import Qt 4.6
import WesControl 1.0

Item {
    height: 80
    width: 90
    Image {
        id: sourcesButton
        source: "remote.png"
        fillMode: "PreserveAspectFit"
        smooth: true
        anchors.horizontalCenter: parent.horizontalCenter
        height: 50
        y: 5
    }
}
