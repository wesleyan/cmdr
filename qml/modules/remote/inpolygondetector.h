#include <QtDeclarative/qmlcontext.h>
#include <QtDeclarative/qmlengine.h>
#include "qml.h"
#include <QPoint>
#include <QRegion>
#include <qmlgraphicsmouseregion_p.h>

#ifndef MaskedMouseRegion_H
#define MaskedMouseRegion_H

class MaskedMouseRegion : public QmlGraphicsMouseRegion
{
    Q_OBJECT
public:

    Q_PROPERTY(QString maskPath READ maskPath WRITE setMaskPath);

    QString maskPath() const;
    void setMaskPath(QString);
protected:
    void mousePressEvent(QGraphicsSceneMouseEvent *event);
private:
    QRegion *region;
    QString m_maskPath;
};
QML_DECLARE_TYPE(MaskedMouseRegion);
#endif // MaskedMouseRegion_H
