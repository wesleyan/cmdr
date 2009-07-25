#include <QDBusMessage>
#include <QDBusError>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QtDeclarative/qmlcontext.h>
#include <QtDeclarative/qmlengine.h>
#include "qml.h"

#ifndef PROJECTOR_H
#define PROJECTOR_H


class Projector : public QObject
{
    Q_OBJECT
public:
    Projector();

    Q_PROPERTY(QString input READ input WRITE setInput NOTIFY inputChanged);
    Q_PROPERTY(bool power READ power WRITE setPower NOTIFY powerChanged);
    Q_PROPERTY(bool video_mute READ videoMute WRITE setVideoMute NOTIFY videoMuteChanged);
    Q_PROPERTY(bool cooling READ cooling NOTIFY coolingChanged(bool));
    Q_PROPERTY(bool warming READ warming NOTIFY warmingChanged(bool));

    QString input() const;
    bool power() const;
    bool videoMute() const;
    bool cooling() const;
    bool warming() const;

    void setPower(bool on);
    void setVideoMute(bool on);
    void setInput(QString input);
    void updateVariables();

    signals:
        void powerChanged(bool);
        void videoMuteChanged(bool);
        void coolingChanged(bool);
        void warmingChanged(bool);
        void inputChanged(QString);
        void sendMessage(QString message, int timeout);

    private slots:
        void power_changed(bool on);
        void video_mute_changed(bool on);
        void cooling_changed(bool on);
        void warming_changed(bool on);
        void input_changed(QString input);
        void responseFromProjector(QDBusMessage message);
        void errorFromProjector(QDBusError error);

    private:
        bool m_power;
        bool m_video_mute;
        bool m_warming;
        bool m_cooling;
        QString m_input;

       // QDBusConnection dbus;
        //static QString service;
        //static QString object;
        //static QString interface;

        QList<QVariant> trueArgument;
        QList<QVariant> falseArgument;

        //QDBusInterface iface;
};
QML_DECLARE_TYPE(Projector);

#endif // PROJECTOR_H
