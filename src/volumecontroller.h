#ifndef VOLUMECONTROLLER_H
#define VOLUMECONTROLLER_H

#include <QObject>
#include "volume.h"

class VolumeController : public QObject
{
    Q_OBJECT
public:
    VolumeController();
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged);
    Q_PROPERTY(bool mute READ mute WRITE setMute NOTIFY muteChanged);
    //Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged);

    double volume() const;
    void setVolume(double volume);

    bool mute() const;
    void setMute(bool mute);

    //bool connected() const;

signals:
    void volumeChanged(double volume);
    void muteChanged(bool mute);

private:
    Volume *volume_device;

};

#endif // VOLUMECONTROLLER_H
