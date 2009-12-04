#include "volumecontroller.h"
#include "qdebug.h"

VolumeController::VolumeController()
{
    volume_device = new Volume("edu.wesleyan.WesControl", "/edu/wesleyan/WesControl/extron",
                       QDBusConnection::systemBus(), this);

    connect(volume_device, SIGNAL(volume_changed(double)), this, SIGNAL(volumeChanged(double)));
    connect(volume_device, SIGNAL(mute_changed(bool)), this, SIGNAL(muteChanged(bool)));
}

double VolumeController::volume() const
{

    return volume_device->volume();
}

bool VolumeController::mute() const
{
    qDebug() << "Mute is " << volume_device->mute();
    return volume_device->mute();
}

void VolumeController::setVolume(double volume)
{
    if(qAbs(volume - volume_device->volume()) > 0.05)
    {
        volume_device->set_volume(volume);
    }
}

void VolumeController::setMute(bool mute)
{
    volume_device->set_mute(mute);
}
