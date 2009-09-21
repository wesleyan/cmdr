import Qt 4.6
Rectangle {
    id: Root
    color: "#000"
    width: 1024
    height: 768

    resources: [

        ListModel {
            id: PagesModelL
            ListElement {
                name: "Projector"
                buttonItemURL: "modules/projector/ProjectorButton.qml"
                pageItemURL: "modules/projector/ProjectorPage.qml"
            }
            ListElement {
                name: "Source"
                buttonItemURL: "modules/sources/SourcesButton.qml"
                pageItemURL: "modules/sources/SourcesPage.qml"
            }
        }
    ]

    Image {
        id: backgroundImage
        width: parent.width
        height: 768 - topBar.height
        source: "../images/olin_blurred.png"
        smooth: true
        y: topBar.height
        
        //filter: Blur { radius: 10 }
    }

    TopBar {
        id: topBar
        height: 45
        width: parent.width
    }

    BottomBar {
        id: bottomBar
        height: 90
        width: parent.width
        anchors.bottom: parent.bottom
        pages: PagesModelL
        currentIndex: pagesView.currentIndex
    }
    PagesView {
        id: pagesView
        currentIndex: bottomBar.currentIndex
        height: parent.height-topBar.height-bottomBar.height
        width: 1024
        anchors.top: topBar.bottom
        pages: PagesModelL
        componentHeight: 560
        componentWidth: 440
    }

    Item {
        id: messageBar
        width: 300
        anchors.top: topBar.bottom
        anchors.topMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 5
        height: messages.count > 0 ? messages.count * 85 + 5 : 0
        height: Behavior {
            SequentialAnimation {
                NumberAnimation {
                    properties: "height"
                    //easing: "easeOutBounce"
                    duration: 200
                }
            }
        }
        Component
        {
            id: MessageComponent
            Item
            {
                height: 85
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                Rectangle {
                    color: "black"
                    radius: 10
                    height: messageText.height + 15 < 80 ? 81 : messageText.height + 15
                    width: parent.width - 10
                    anchors.centerIn: parent
                    opacity: 0.75
                    Text {
                        id: messageText
                        width: parent.width - 10
                        text: message
                        font.family: "Myriad Pro"
                        font.pointSize: 14
                        color: "white"
                        anchors.centerIn: parent
                        wrap: true
                    }
                }
            }
        }

        ListView {
            id: messageListView
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            height: parent.height
            width: parent.width
            model: messages
            delegate: MessageComponent
            interactive: false
        }
    }
}

