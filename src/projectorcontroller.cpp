#include "projectorcontroller.h"
#include <QDebug>

ProjectorController::ProjectorController()
{
    projector = new Projector("edu.wesleyan.WesControl", "/edu/wesleyan/WesControl/projector",
                           QDBusConnection::systemBus(), this);

    connect(projector, SIGNAL(power_changed(bool)), this, SLOT(power_changed(bool)));
    connect(projector, SIGNAL(cooling_changed(bool)), this, SLOT(cooling_changed(bool)));
    connect(projector, SIGNAL(video_mute_changed(bool)), this, SLOT(video_mute_changed(bool)));
    connect(projector, SIGNAL(warming_changed(bool)), this, SLOT(warming_changed(bool)));
    connect(projector, SIGNAL(error(QString)), this, SLOT(projector_error(QString)));

    QState *offState = new QState();
    QState *onState = new QState();
    QState *muteState = new QState();
    QState *warmingState = new QState();
    QState *coolingState = new QState();

    offState->addTransition(this, SIGNAL(warming_on()), warmingState);
    warmingState->addTransition(this, SIGNAL(warming_off()), onState);
    //warmingState->addTransition(this, SIGNAL(power_on()), onState);
    onState->addTransition(this, SIGNAL(video_mute_on()), muteState);
    onState->addTransition(this, SIGNAL(cooling_on()), coolingState);
    onState->addTransition(this, SIGNAL(power_off()), offState);
    muteState->addTransition(this, SIGNAL(cooling_on()), coolingState);
    muteState->addTransition(this, SIGNAL(video_mute_off()), onState);
    coolingState->addTransition(this, SIGNAL(power_off()), offState);
    coolingState->addTransition(this, SIGNAL(cooling_off()), offState);

    /*coolingState->assignProperty(projector, "power", false);
    warmingState->assignProperty(projector, "power", true);
    offState->assignProperty(projector, "power", false);
    onState->assignProperty(projector, "power", QVariant(true));
    muteState->assignProperty(projector, "video_mute", QVariant(true));
    onState->assignProperty(projector, "video_mute", QVariant(false));*/

    coolingState->assignProperty(this, "state", "coolingState");
    warmingState->assignProperty(this, "state", "warmingState");
    offState->assignProperty(this, "state", "offState");
    onState->assignProperty(this, "state", "onState");
    muteState->assignProperty(this, "state", "muteState");

    connect(offState, SIGNAL(entered()), this, SIGNAL(stateChanged()));
    connect(onState, SIGNAL(entered()), this, SIGNAL(stateChanged()));
    connect(muteState, SIGNAL(entered()), this, SIGNAL(stateChanged()));
    connect(warmingState, SIGNAL(entered()), this, SIGNAL(stateChanged()));
    connect(coolingState, SIGNAL(entered()), this, SIGNAL(stateChanged()));

    stateMachine.addState(offState);
    stateMachine.addState(onState);
    stateMachine.addState(muteState);
    stateMachine.addState(warmingState);
    stateMachine.addState(coolingState);


    if(projector->warming())stateMachine.setInitialState(warmingState);
    else if(projector->cooling())stateMachine.setInitialState(coolingState);
    else if(!projector->power())stateMachine.setInitialState(offState);
    else if(projector->video_mute())stateMachine.setInitialState(muteState);
    else stateMachine.setInitialState(onState);

    stateMachine.start();
}

QString ProjectorController::state() const
{
    return m_state;
}

void ProjectorController::setState(QString state)
{
    m_state = state;
    qDebug() << "State changed to " << state;
    emit stateChanged();
}

void ProjectorController::setPower(bool on)
{
    projector->set_power(on);
}

void ProjectorController::setVideoMute(bool on)
{
    projector->set_video_mute(on);
}

void ProjectorController::video_mute_changed(bool on)
{
    if(on) emit video_mute_on();
    else emit video_mute_off();
}

void ProjectorController::warming_changed(bool on)
{
    if(on) emit warming_on();
    else emit warming_off();
}

void ProjectorController::cooling_changed(bool on)
{
    if(on) emit cooling_on();
    else emit cooling_off();
}

void ProjectorController::power_changed(bool on)
{
    qDebug() << "Power changed " << on;
    if(on) emit power_on();
    else emit power_off();
}

void ProjectorController::projector_error(QString message)
{
    qDebug() << "Error: " << message;
    emit sendMessage(message, 1000);
}
