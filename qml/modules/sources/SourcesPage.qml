import Qt 4.6
import WesControl
Item {
    anchors.fill: parent
    Item {
        anchors.fill: parent
        z: sourcecontroller.connected? -1 : -1
        opacity: sourcecontroller.connected? 0 : 0
        Rectangle {
            color: "black"
            radius: 20
            opacity: 0.95
            anchors.fill: parent
            anchors.horizontalCenter: parent.horizontalCenter
            MouseRegion {
                anchors.fill: parent
            }
        }
        Text {
            id: unableToConnectText
            text: "Unable to connect to Extron"
            font.family: "Myriad Pro"
            font.pointSize: 40
            color: "white"
            wrap: true
            width: parent.width-30
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 100
            horizontalAlignment: "AlignHCenter"
        }
        Text {
            text: "Please call #4959 for assistance"
            font.family: "Myriad Pro"
            font.pointSize: 20
            color: "white"
            width: parent.width-30
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: unableToConnectText.bottom
            anchors.topMargin: 50
            horizontalAlignment: "AlignHCenter"
        }
    }

    Rectangle {
        resources: [
            XmlListModel {
                id: SourcesModel
                source: "../../../pages.xml"
                query: "/WesControl/page[name=\"Source\"]/configuration/sources/source"
                XmlRole {
                    name: "name"
                    query: "name/string()"
                }
                XmlRole {
                    name: "imageSource"
                    query: "image/@source/string()"
                }
                XmlRole {
                    name: "imageWidth"
                    query: "image/@width/number()"
                }
                XmlRole {
                    name: "imageHeight"
                    query: "image/@height/number()"
                }
            }
        ]
        height: parent.height
        width: parent.width
        radius: 20
        color:"#F2F2F2"
        opacity: 0.9
        clip: true

        Component {
            id: ListDelegate
            Item {
                height: 90
                width: parent.width
                Item {
                    id: imageBox
                    width: 150
                    height: parent.height
                    Image {
                        source: "images/" + imageSource
                        width: imageWidth
                        height: imageHeight
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        smooth: true
                    }
                }
                Item {
                    height: parent.height
                    anchors.left: imageBox.right
                    Text {
                        id: nameText
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Myriad Pro"
                        font.pointSize: 54
                        text: name
                        color: "black"
                    }
                }
                Rectangle {
                    height: 1
                    width: parent.width
                    color: "#555555"
                    opacity: 0.3
                    anchors.top: parent.bottom
                    z: -5
                }
                MouseRegion {
                    id: sourceMouseRegion
                    anchors.fill: parent
                    onPressed: {
                        if(sourcesView.currentIndex != index)sourcecontroller.source = name
                        //sourcesView.currentIndex = index
                    }
                }
                Connection {
                    sender: sourcecontroller
                    signal: "sourceChanged()"
                    script: {
                        if(sourcecontroller.source == name)sourcesView.currentIndex = index
                    }
                }
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: {
                        if(sourcecontroller.source == name)sourcesView.currentIndex = index
                    }
                }
                states: [
                    State {
                        name: "selected"
                        when: sourcesView.currentIndex == index
                        PropertyChanges {
                            target: nameText
                            color: "white"
                        }
                    }
                ]
                transitions: [
                    Transition {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: 50
                            }
                            ColorAnimation {
                                duration: 300
                            }
                        }
                    }
                ]
            }
        }

        Item {
            id: backgroundRect
            width: parent.width
            height: 90
            clip: true
            Rectangle {
                id: gradientRect
                smooth: true
                width: parent.width
                height: 90
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#6E6E6E"
                    }
                    GradientStop {
                        position: 1
                        color: "#292929"
                    }
                }
            }
            y: SpringFollow {
                 source: sourcesView.currentItem.y
                 spring: 5
                 damping: 0.3
            }
            z: 0
            states: [
                State {
                    name: "up"
                    when: sourcesView.currentIndex == 0
                    PropertyChanges {
                        target: gradientRect
                        height: 110
                        radius: 20
                    }
                },
                State {
                    name: "down"
                    when: sourcesView.currentIndex != 0
                    PropertyChanges {
                        target: gradientRect
                        radius: 0
                    }
                }
            ]
            transitions: [
                Transition {
                    NumberAnimation {
                        properties: "radius"
                        duration: 100
                    }
                }
            ]
        }

        ListView {
            id: sourcesView
            height: parent.height
            width: parent.width
            delegate: ListDelegate
            model: SourcesModel
            //highlight: highlightComponent
            clip: true
            interactive: false
        }
    }
}
