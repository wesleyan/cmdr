import Qt 4.6
import WesControl 1.0

Item {
    /*resources: [
        XmlListModel {
            id: SourcesModel
            source: "../../../pages.xml"
            query: "/WesControl/page[name=\"Source\"]/configuration/sources/source[name=\"" + currentSource + "\"]"
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
        }/*,
        Component {
            id: ImageComponent
            Rectangle {
                width: 100
                height: 100
                color: "blue"
            }
            Connection {
                sender: sourcecontroller
                signal: "sourceChanged()"
                script: {
                    print("THE BUTTON SAW THE SOURCE CHANGE!!!");
                    if(sourcecontroller.source == name)sourcesButton.source = imageSource

                }
            }
        }*
    ]*/
    height: 80
    width: 90
    Image {
        id: sourcesButton
        height: 40
        width: 70
        smooth: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
        source: "images/" + sourcecontroller.sourceImageURL
        fillMode: "PreserveAspectFit"
    }
}
