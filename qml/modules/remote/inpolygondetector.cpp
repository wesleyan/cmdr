#include "inpolygondetector.h"
#include <qml.h>
#include <QPixmap>
#include <QBitmap>
#include <QPoint>
#include <QDebug>
#include <QGraphicsSceneMouseEvent>

QML_DEFINE_TYPE(WesControl, 1, 0, 0, InPolygonDetector, MaskedMouseRegion);

InPolygonDetector::InPolygonDetector()
{
}


QString InPolygonDetector::maskPath() const
{
    return m_maskPath;
}
void InPolygonDetector::setMaskPath(QString maskPath)
{
    QPixmap bm(maskPath);
    region = new QRegion(bm.mask());
    qDebug() << "Image: " << bm.size();
    m_maskPath = maskPath;
}
void InPolygonDetector::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if(region->contains(event->pos().toPoint()))
    {
        QFxMouseRegion::mousePressEvent(event);
    }
    else
    {
        event->ignore();
    }
}
