import Qt 4.6
import WesControl 1.0

Item {
    height: 80
    width: 90
    Image {
        id: sourcesButton
        source: "remote.png"
        smooth: true
        anchors.horizontalCenter: parent.horizontalCenter
        preserveAspect: true
        height: 50
        y: 5
    }
}
