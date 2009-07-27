#include <QtDeclarative/qmlcontext.h>
#include <QtDeclarative/qmlengine.h>
#include "qml.h"
#include <QPoint>
#include <QRegion>

#ifndef INPOLYGONDETECTOR_H
#define INPOLYGONDETECTOR_H

class InPolygonDetector : public QObject
{
    Q_OBJECT
public:
    InPolygonDetector();

    Q_PROPERTY(int testX READ testX WRITE setTestX);
    Q_PROPERTY(int testY READ testY WRITE setTestY);
    Q_PROPERTY(bool inPolygon READ inPolygon NOTIFY inPolygonChanged(bool));
    Q_PROPERTY(QString imagePath READ imagePath WRITE setImagePath);

    int testX() const;
    void setTestX(int);
    int testY() const;
    void setTestY(int);
    bool inPolygon() const;
    QString imagePath() const;
    void setImagePath(QString);
signals:
    void inPolygonChanged(bool);
private:
    bool m_inPolygon;
    QPoint m_testPoint;
    QRegion *region;
    QString m_imagePath;
    void update();

};
QML_DECLARE_TYPE(InPolygonDetector);
#endif // INPOLYGONDETECTOR_H
