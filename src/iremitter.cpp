#include "iremitter.h"
#include <QDebug>

IREmitter::IREmitter()
{
    service   = "edu.wesleyan.WesControl";
    object    = "/edu/wesleyan/WesControl/dvd_vcr_remote";
    interface = "edu.wesleyan.WesControl.irEmitter";
}

void IREmitter::send_command(QString command)
{
    QList<QVariant> inputArgument;
    inputArgument << QVariant(command);
    QDBusInterface iface(service, object, interface, QDBusConnection::sessionBus());
    iface.callWithCallback("pulse_command",
                           inputArgument,
                           this,
                           SLOT(responseFromServer(QDBusMessage)),
                           SLOT(errorFromServer(QDBusError)));
}


void IREmitter::responseFromServer(QDBusMessage message)
{
    qDebug() << "Received message: " << message.signature() << "=" << message.arguments().first().toString();
    //if(message.arguments().first().toString() != "")emit sendMessage(message.arguments().first().toString(), 5000);
}

void IREmitter::errorFromServer(QDBusError error)
{
    qDebug() << "Received error: " << error.message() << "=" << error.name();
}

