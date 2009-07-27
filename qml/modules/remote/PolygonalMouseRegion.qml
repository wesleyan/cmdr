MouseRegion {
    property alias imagePath: ipd.imagePath
    signal pressedInside
    signal clickedInside

    InPolygonDetector { id: ipd }

    onPressed: {
        ipd.testX = mouse.x
        ipd.testY = mouse.y
        if(ipd.inPolygon)pressedInside();
    }
    onClicked: {
        ipd.testX = mouse.x
        ipd.testY = mouse.y
        if(ipd.inPolygon)clickedInside();
    }
}
