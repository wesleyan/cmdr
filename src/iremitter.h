#ifndef IREMITTER_H
#define IREMITTER_H

#include <QDBusMessage>
#include <QDBusError>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QtDeclarative/qmlcontext.h>
#include <QtDeclarative/qmlengine.h>
#include "qml.h"


class IREmitter : public QObject
{
Q_OBJECT
public:
    IREmitter();

public slots:
    void pulse_command(QString command);
    void responseFromServer(QDBusMessage message);
    void errorFromServer(QDBusError error);

private:
    QString service, object, interface;
};

#endif // IREMITTER_H
