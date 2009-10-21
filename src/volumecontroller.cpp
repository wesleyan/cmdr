#include "volumecontroller.h"

VolumeController::VolumeController()
{
    volume_device = new Volume("edu.wesleyan.WesControl", "/edu/wesleyan/WesControl/extron",
                       QDBusConnection::systemBus(), this);

    connect(volume_device, SIGNAL(volume_changed(double)), this, SIGNAL(volumeChanged(double)));
    connect(volume_device, SIGNAL(mute_changed(bool)), this, SLOT(muteChanged(bool)));
}

double VolumeController::volume() const
{
    return volume_device->volume();
}

bool VolumeController::mute() const
{
    return volume_device->mute();
}

void VolumeController::setVolume(double volume)
{
    volume_device->set_volume(volume);
}

void VolumeController::setMute(bool mute)
{
    volume_device->set_mute(mute);
}
