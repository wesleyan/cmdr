#include "videoswitcher.h"
#include <QtDBus>
#include <QDBusInterface>
#include <QDebug>
#include <QDBusMessage>
#include <QDBusError>
#include <QDBusReply>
#include <QtDeclarative/qmlcontext.h>
#include <QtDeclarative/qmlengine.h>
#include "qml.h"

QDBusConnection switcher_dbus = QDBusConnection::systemBus();
QString switcher_service    = "edu.wesleyan.WesControl";
QString switcher_object    = "/edu/wesleyan/WesControl/extron";
QString switcher_interface  = "edu.wesleyan.WesControl.videoSwitcher";

QDBusInterface switcher_iface(switcher_service, switcher_object, switcher_interface, switcher_dbus);

QML_DEFINE_TYPE(WesControl, 1, 0, 0, VideoSwitcher, VideoSwitcher);

VideoSwitcher::VideoSwitcher()
{
    qDebug() << "Starting connections";
    connect(this, SIGNAL(inputChanged(int)), this, SLOT(input_changed(int)));
    bool connected = switcher_dbus.connect(switcher_service,
                        switcher_object,
                        switcher_interface,
                        "input_changed",
                        this,
                        SIGNAL(inputChanged(int)));

    qDebug() << "Starting extron calls";

    QDBusReply<int> reply;

    reply = switcher_iface.call(QDBus::BlockWithGui, "input");
    if(reply.isValid())m_input = reply.value();
    connected = connected && reply.isValid();

    qDebug() << "Done with extron calls";

    if(m_connected != connected)
    {
        m_connected = connected;
        emit connectedChanged(m_connected);
    }

    if(!connected)
    {
        qDebug() << "Not connected to extron";
        //emit sendMessage("Failed to communicate with server", 5000);
    }

}

bool VideoSwitcher::connected() const
{
    return m_connected;
}

int VideoSwitcher::input() const
{
    return m_input;
}

void VideoSwitcher::input_changed(int input)
{
    qDebug("Extron input changed");
    //if(m_input != input)emit inputChanged();
    m_input = input;
}

void VideoSwitcher::setInput(int input)
{
    if(input != m_input)
    {
        QList<QVariant> argument;
        argument << QVariant(input);
        switcher_iface.callWithCallback("set_input",
                           argument,
                           this,
                           SLOT(responseFromSwitcher(QDBusMessage)),
                           SLOT(errorFromSwitcher(QDBusError)));
    }
    m_input = input;
}

void VideoSwitcher::responseFromSwitcher(QDBusMessage message)
{
    qDebug() << "Received message: " << message.signature() << "=" << message.arguments().first().toString();
    if(message.arguments().first().toString() != "")emit sendMessage(message.arguments().first().toString(), 5000);
}

void VideoSwitcher::errorFromSwitcher(QDBusError error)
{
    qDebug() << "Received error: " << error.message() << "=" << error.name();
}
