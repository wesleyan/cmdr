#include "volume.h"
#include <QtDBus>
#include <QDBusInterface>
#include <QDebug>
#include <QDBusMessage>
#include <QDBusError>
#include <QDBusReply>
#include <QtDeclarative/qmlcontext.h>
#include <QtDeclarative/qmlengine.h>
#include "qml.h"

QDBusConnection volume_dbus = QDBusConnection::sessionBus();
QString volume_service    = "edu.wesleyan.WesControl";
QString volume_object    = "/edu/wesleyan/WesControl/extron";
QString volume_interface  = "edu.wesleyan.WesControl.videoSwitcher";

QDBusInterface volume_iface(volume_service, volume_object, volume_interface, volume_dbus);

QML_DEFINE_TYPE(WesControl, 1, 0, 0, Volume, Volume);

Volume::Volume()
{
    qDebug() << "Starting Volume Connections";
    connect(this, SIGNAL(volumeChanged(double)), this, SLOT(volume_changed(double)));
    connect(this, SIGNAL(muteChanged(bool)), this, SLOT(mute_changed(bool)));
    bool connected = volume_dbus.connect(volume_service,
                        volume_object,
                        volume_interface,
                        "volume_changed",
                        this,
                        SIGNAL(volumeChanged(double)));

    connected = connected && volume_dbus.connect(volume_service,
                        volume_object,
                        volume_interface,
                        "mute_changed",
                        this,
                        SIGNAL(muteChanged(bool)));


    qDebug() << "Starting volume calls";

    QDBusReply<double> reply = volume_iface.call(QDBus::BlockWithGui, "volume");
    if(reply.isValid())m_volume = reply.value();
    connected = connected && reply.isValid();

    QDBusReply<bool> bool_reply = volume_iface.call(QDBus::BlockWithGui, "mute");
    if(reply.isValid())m_mute = reply.value();
    connected = connected && reply.isValid();

    qDebug() << "Done with volume calls";

    if(!connected)
    {
        qDebug() << "Not connected to volume controller";
        //emit sendMessage("Failed to communicate with server", 5000);
    }

}

double Volume::volume() const
{
    return m_volume;
}

void Volume::volume_changed(double volume)
{
    //if(m_volume != volume)emit volumeChanged(volume);
    m_volume = volume;
}

void Volume::setVolume(double volume)
{
    qDebug() << "Setting volume to " << volume;
    QList<QVariant> argument;
    argument << QVariant(volume);
    volume_iface.callWithCallback("set_volume",
                       argument,
                       this,
                       SLOT(responseFromSwitcher(QDBusMessage)),
                       SLOT(errorFromSwitcher(QDBusError)));
    m_volume = volume;
}

bool Volume::mute() const
{
    return m_mute;
}

void Volume::mute_changed(bool mute)
{
    if(m_mute != mute)emit muteChanged(mute);
    m_mute = mute;
}

void Volume::setMute(bool mute)
{
    QList<QVariant> argument;
    argument << QVariant(mute);
    volume_iface.callWithCallback("set_mute",
                       argument,
                       this,
                       SLOT(responseFromSwitcher(QDBusMessage)),
                       SLOT(errorFromSwitcher(QDBusError)));
    m_mute = mute;
}

void Volume::responseFromSwitcher(QDBusMessage message)
{
    qDebug() << "Received message: " << message.signature() << "=" << message.arguments().first().toString();
    //if(message.arguments().first().toString() != "")emit sendMessage(message.arguments().first().toString(), 5000);
}

void Volume::errorFromSwitcher(QDBusError error)
{
    qDebug() << "Received error: " << error.message() << "=" << error.name();
}
