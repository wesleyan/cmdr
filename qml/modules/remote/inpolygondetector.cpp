#include "inpolygondetector.h"
#include <qml.h>
#include <QPixmap>
#include <QBitmap>
#include <QPoint>
#include <QDebug>
#include <QGraphicsSceneMouseEvent>

QML_DEFINE_TYPE(WesControl, 1, 0, 0, MaskedMouseRegion);


QString MaskedMouseRegion::maskPath() const
{
    return m_maskPath;
}
void MaskedMouseRegion::setMaskPath(QString maskPath)
{
    QPixmap bm(maskPath);
    region = new QRegion(bm.mask());
    m_maskPath = maskPath;
}
void MaskedMouseRegion::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if(region->contains(event->pos().toPoint()))
    {
        QmlGraphicsMouseRegion::mousePressEvent(event);
    }
    else
    {
        event->ignore();
    }
}
