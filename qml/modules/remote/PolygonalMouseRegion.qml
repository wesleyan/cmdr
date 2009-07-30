import Qt 4.6
import WesControl 1.0
MouseRegion {
    property alias imagePath: ipd.imagePath
    signal pressedInside
    signal clickedInside

    InPolygonDetector {
        id: ipd
    }

    //enabled: ipd.inPolygon

    onPressed: {
        print(mouseX)
        //ipd.testX = mouse.x
        //ipd.testY = mouse.y
        //if(ipd.inPolyon)pressedInside();
    }
    onClicked: {
        ipd.testX = mouse.x
        ipd.testY = mouse.y
        if(ipd.inPolygon)clickedInside();
    }
}
