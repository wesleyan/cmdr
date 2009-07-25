#include <QDBusMessage>
#include <QDBusError>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QtDeclarative/qmlcontext.h>
#include <QtDeclarative/qmlengine.h>
#include "qml.h"

#ifndef VIDEOSWITCHER_H
#define VIDEOSWITCHER_H

class VideoSwitcher : public QObject
{
    Q_OBJECT
public:
    VideoSwitcher();

    Q_PROPERTY(int input READ input WRITE setInput NOTIFY inputChanged);

    int input() const;
    void setInput(int input);

    signals:
        void inputChanged(int);
        void sendMessage(QString message, int timeout);

    private slots:
        void input_changed(int input);
        void responseFromSwitcher(QDBusMessage message);
        void errorFromSwitcher(QDBusError error);

    private:
        int m_input;
};
QML_DECLARE_TYPE(VideoSwitcher);

#endif // VIDEOSWITCHER_H
