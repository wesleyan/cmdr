#include "projector.h"

#include <QtDBus>
#include <QDBusInterface>
#include <QDebug>
#include <QDBusMessage>
#include <QDBusError>
#include <QDBusReply>

#include <QtDeclarative/qmlcontext.h>
#include <QtDeclarative/qmlengine.h>
#include "qml.h"

QDBusConnection dbus = QDBusConnection::systemBus();
QString service   = "edu.wesleyan.WesControl";
QString object    = "/edu/wesleyan/WesControl/projector";
QString interface = "edu.wesleyan.WesControl.projector";

QDBusInterface iface(service, object, interface, dbus);


QML_DEFINE_TYPE(WesControl , 1, 0, 0, Projector, Projector);

Projector::Projector()
{

    trueArgument << QVariant(true);
    falseArgument << QVariant(false);


    connect(this, SIGNAL(powerChanged(bool)), this, SLOT(power_changed(bool)));
    connect(this, SIGNAL(videoMuteChanged(bool)), this, SLOT(video_mute_changed(bool)));
    connect(this, SIGNAL(coolingChanged(bool)), this, SLOT(cooling_changed(bool)));
    connect(this, SIGNAL(warmingChanged(bool)), this, SLOT(warming_changed(bool)));
    connect(this, SIGNAL(inputChanged(QString)), this, SLOT(input_changed(QString)));

    qDebug() << "Starting connections";
    bool connected = true;

    connected = connected && dbus.connect(service,
                                          object,
                                          interface,
                                          "power_changed",
                                          this,
                                          SIGNAL(powerChanged(bool)));
    connected = connected && dbus.connect(service,
                                          object,
                                          interface,
                                          "video_mute_changed",
                                          this,
                                          SIGNAL(videoMuteChanged(bool)));
    connected = connected && dbus.connect(service,
                                          object,
                                          interface,
                                          "cooling_changed",
                                          this,
                                          SIGNAL(coolingChanged(bool)));
    connected = connected && dbus.connect(service,
                                          object,
                                          interface,
                                          "warming_changed",
                                          this,
                                          SIGNAL(warmingChanged(bool)));
    connected = connected && dbus.connect(service,
                                          object,
                                          interface,
                                          "input_changed",
                                          this,
                                          SIGNAL(inputChanged(QString)));

    qDebug() << "Starting calls";
    QDBusReply<bool> reply;

    reply = iface.call("power");
    if(reply.isValid())m_power = reply.value();
    connected = connected && reply.isValid();

    reply = iface.call("video_mute");
    if(reply.isValid())m_video_mute = reply.value();
    connected = connected && reply.isValid();

    reply = iface.call("warming");
    if(reply.isValid())m_warming = reply.value();
    connected = connected && reply.isValid();

    reply = iface.call("cooling");
    if(reply.isValid())m_cooling = reply.value();
    connected = connected && reply.isValid();

    QDBusReply<QString> stringReply;
    stringReply = iface.call("input");
    if(stringReply.isValid())m_input = stringReply.value();
    connected = connected && stringReply.isValid();

    qDebug() << "Done with setup";

    if(m_connected != connected)
    {
        m_connected = connected;
        emit connectedChanged(m_connected);
    }
    
    if(!connected)
    {
        qDebug() << "Not connected";
        emit sendMessage("Failed to communicate with server", 5000);
    }

}

bool Projector::connected() const
{
    return m_connected;
}

QString Projector::input() const
{
    return m_input;
}

bool Projector::power() const
{
    return m_power;
}

bool Projector::videoMute() const
{
    return m_video_mute;
}

bool Projector::warming() const
{
    return m_warming;
}

bool Projector::cooling() const
{
    return m_cooling;
}

void Projector::power_changed(bool on)
{
    m_power = on;
}

void Projector::video_mute_changed(bool on)
{
    m_video_mute = on;
}

void Projector::cooling_changed(bool on)
{
    m_cooling = on;
}

void Projector::warming_changed(bool on)
{
    m_warming = on;
}

void Projector::input_changed(QString input)
{
    m_input = input;
}

void Projector::setPower(bool on)
{
                emit sendMessage("Tried to turn on", 10000);

    iface.callWithCallback("set_power",
                           on ? trueArgument : falseArgument,
                           this,
                           SLOT(responseFromProjector(QDBusMessage)),
                           SLOT(errorFromProjector(QDBusError)));
}

void Projector::setVideoMute(bool on)
{
    iface.callWithCallback("set_video_mute",
                           on ? trueArgument : falseArgument,
                           this,
                           SLOT(responseFromProjector(QDBusMessage)),
                           SLOT(errorFromProjector(QDBusError)));
}

void Projector::setInput(QString input)
{
    qDebug() << "Setting projector input to " << input;
    QList<QVariant> inputArgument;
    inputArgument << QVariant(input);
    iface.callWithCallback("set_input",
                           inputArgument,
                           this,
                           SLOT(responseFromProjector(QDBusMessage)),
                           SLOT(errorFromProjector(QDBusError)));
}


void Projector::responseFromProjector(QDBusMessage message)
{
    qDebug() << "Received message: " << message.signature() << "=" << message.arguments().first().toString();
    if(message.arguments().first().toString() != "")emit sendMessage(message.arguments().first().toString(), 5000);
}

void Projector::errorFromProjector(QDBusError error)
{
    qDebug() << "Received error: " << error.message() << "=" << error.name();
}
