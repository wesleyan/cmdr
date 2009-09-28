#ifndef PROJECTORCONTROLLER_H
#define PROJECTORCONTROLLER_H

#include <QStateMachine>
#include "projector.h"

class ProjectorController : public QObject
{
Q_OBJECT
    public:
        ProjectorController();
        Q_PROPERTY(QString state READ state WRITE setState NOTIFY stateChanged);
        //Q_PROPERTY(bool power, READ power WRITE setPower

        QString state() const;
        void setState(QString state);

    signals:
        void stateChanged();

        void cooling_on();
        void cooling_off();
        void warming_on();
        void warming_off();
        void power_on();
        void power_off();
        void video_mute_on();
        void video_mute_off();

    public slots:
        void setPower(bool on);
        void setVideoMute(bool on);

    private slots:
        void cooling_changed(bool on);
        void warming_changed(bool on);
        void power_changed(bool on);
        void video_mute_changed(bool on);

    private:
        QStateMachine stateMachine;
        Projector *projector;
        QString m_state;

};

#endif // SOURCECONTROLLER_H
