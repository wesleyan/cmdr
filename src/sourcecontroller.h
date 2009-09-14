#ifndef SOURCECONTROLLER_H
#define SOURCECONTROLLER_H

#include <QObject>
#include <QStateMachine>
#include "projector.h"
#include "videoswitcher.h"

class SourceController : public QObject
{
Q_OBJECT
public:
    SourceController();

    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged);
    Q_PROPERTY(QString state READ state WRITE setState);
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged);
    QString source() const;
    void setSource(QString source);
    QString state() const;
    void setState(QString state);
    bool connected() const;

    signals:
        void sourceChanged();
        void connectedChanged(bool connected);
        //void sendMessage(QString message, int timeout);

    private slots:
        void projector_input_changed(QString input);
        void switcher_input_changed();
        void projector_power_changed(bool on);

    private:
        QString m_source;
        QStateMachine stateMachine;
        Projector *projector;
        VideoSwitcher *switcher;
        QString m_state;
        QHash<int, QString> nameToExtronMap;
};

#endif // SOURCECONTROLLER_H
