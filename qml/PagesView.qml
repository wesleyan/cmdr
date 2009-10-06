import Qt 4.6
Item {
    property var pages
    property double componentHeight
    property double componentWidth
    property alias currentIndex: pagesView.currentIndex

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
        },
        XmlListModel {
            id: PagesModel
            source: "../pages.xml"
            query: "/WesControl/page"
            XmlRole {
                name: "name"
                query: "name/string()"
            }
            XmlRole {
                name: "pageItemURL"
                query: "pageItemURL/string()"
            }
        },
        Component {
            id: PagesDelegate
            Item {
                height: componentHeight
                width: componentWidth + 20
                anchors.verticalCenter: parent.verticalCenter
                Item {
                    id: pageRect
                    opacity: 1
                    height: componentHeight
                    width: componentWidth
                    //transform: Rotation3D { id: rotation; axis.endY: 60; angle: 0 }
                    Loader {
                        id: pageItem
                        source: pageItemURL
                        anchors.fill: parent

                    }
                    states: [
                        State {
                            name: "rightOfIndex"
                            PropertyChanges {
                                target: rotation
                                angle: 29
                                axis.startX: 0
                                axis.endX: 0
                            }
                            /*PropertyChanges {
                                target: pageRect
                                opacity: 0.6
                                scale: 0.6
                            }*/
                            //when: currentIndex > index
                        },
                        State {
                            name: "leftOfIndex"
                            PropertyChanges {
                                target: rotation
                                angle: -29
                                axis.startX: componentWidth
                                axis.endX: componentWidth
                            }
                            /*PropertyChanges {
                                target: pageRect
                                opacity: 0.6
                                scale: 0.6
                            }*/

                            //when: currentIndex < index
                        }
                    ]
                    transitions: [
                        Transition {
                            from: ""
                            to: "*"
                            SequentialAnimation {
                                PropertyAction {
                                    target: rotation;
                                    properties: "axis.startX,axis.startY";
                                }
                                NumberAnimation {
                                    properties: "angle"
                                    duration: 300
                                }
                            }
                        },
                        Transition {
                            from: "leftOfIndex"
                            to: ""
                            SequentialAnimation {
                                NumberAnimation {
                                    properties: "angle"
                                    duration: 300
                                }
                                PropertyAction {
                                    target: rotation;
                                    properties: "axis.startX,axis.endX";
                                }
                            }
                        },
                        Transition {
                            from: "rightOfIndex"
                            to: ""
                            SequentialAnimation {
                                PropertyAction {
                                    target: rotation;
                                    properties: "axis.startX,axis.endX";
                                }
                                NumberAnimation {
                                    properties: "angle"
                                    duration: 300
                                }
                            }
                        }

                    ]
                }
            }
        }
    ]

    ListView {
        id: pagesView
        anchors.fill: parent
        model: PagesModel
        delegate: PagesDelegate
        orientation: "Horizontal"
        //snapPosition: parent.width/2 - (componentWidth+20)/2
        preferredHighlightBegin: parent.width/2 - (componentWidth+20)/2
        preferredHighlightEnd: parent.width/2 + (componentWidth+20)/2
        strictlyEnforceHighlightRange: true
        maximumFlickVelocity: 700
        cacheBuffer: 5000
    }
}
