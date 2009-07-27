#include "inpolygondetector.h"
#include <qml.h>
#include <QPixmap>
#include <QBitmap>
#include <QPoint>
#include <QDebug>

QML_DEFINE_TYPE(InPolygonDetector, InPolygonDetector);

InPolygonDetector::InPolygonDetector()
{
}

int InPolygonDetector::testX() const
{
    return (&m_testPoint)->x();
}
int InPolygonDetector::testY() const
{
    return (&m_testPoint)->y();
}
void InPolygonDetector::setTestX(int x)
{
    (&m_testPoint)->setX(x);
}
void InPolygonDetector::setTestY(int y)
{
    (&m_testPoint)->setY(y);
    update();
}

QString InPolygonDetector::imagePath() const
{
    return m_imagePath;
}
void InPolygonDetector::setImagePath(QString imagePath)
{
    QPixmap bm(imagePath);
    region = new QRegion(bm.mask());
    qDebug() << "Image: " << bm.size();
}

void InPolygonDetector::update()
{
    bool in = region->contains(m_testPoint);
    if(m_inPolygon != in)emit inPolygonChanged(in);
    m_inPolygon = in;
}

bool InPolygonDetector::inPolygon() const
{
    return m_inPolygon;
}
