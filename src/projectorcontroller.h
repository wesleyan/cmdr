#ifndef PROJECTORCONTROLLER_H
#define PROJECTORCONTROLLER_H

#include <QStateMachine>
#include "projector.h"

class ProjectorController
{
Q_OBJECT
    public:
        ProjectorController();
        Q_PROPERTY(QString state READ state WRITE setState NOTIFY stateChanged);

        QString state() const;
        void setState(QString state);

    signals:
        void stateChanged();

    private slots:
        void input_changed(QString input);
        void power_changed(bool on);
        void video_mute_changed(bool on);
        void cooling_changed(bool on);
        void warming_chagned(bool on);

    private:
        QStateMachine stateMachine;
        Projector *projector;
        QString m_state;

};

#endif // SOURCECONTROLLER_H
