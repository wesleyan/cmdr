#include "sourcecontroller.h"
#include <QtXmlPatterns>
#include <QDebug>

struct StringEvent : public QEvent
{
    StringEvent(const QString &val)
    : QEvent(QEvent::Type(QEvent::User+1)),
    value(val) {}

    QString value;
};
class StringTransition : public QAbstractTransition
{
public:
    StringTransition(const QString &value, const QString &projector_input, const int &extron_input, Projector *projector, VideoSwitcher *switcher)
    : m_value(value), m_projector_input(projector_input), m_extron_input(extron_input),
    m_projector(projector), m_switcher(switcher){}

protected:
    virtual bool eventTest(QEvent *e)
    {
        if (e->type() != QEvent::Type(QEvent::User+1)) // StringEvent
        return false;
        StringEvent *se = static_cast<StringEvent*>(e);
        return (m_value == se->value);
    }
    virtual void onTransition(QEvent *)
    {
            m_projector->set_input(m_projector_input);
            qDebug() << "Switched projector to " << m_projector_input << " from " << m_projector->input();
            m_switcher->set_input(m_extron_input);
            qDebug() << "Switched extron to " << m_extron_input;
    }

private:
    QString m_value;
    QString m_projector_input;
    int m_extron_input;
    Projector *m_projector;
    VideoSwitcher *m_switcher;
};

SourceController::SourceController()
{
    projector = new Projector("edu.wesleyan.WesControl", "/edu/wesleyan/WesControl/projector",
                           QDBusConnection::systemBus(), this);

    switcher = new VideoSwitcher("edu.wesleyan.WesControl", "/edu/wesleyan/WesControl/extron",
                           QDBusConnection::systemBus(), this);

    QXmlQuery query;
    QStringList names;
    QStringList projector_inputs;
    QStringList switcher_inputs;
    QStringList image_urls;
    query.setQuery("doc('pages.xml')//page[name=\"Source\"]/configuration/sources/source/name/string()");
    query.evaluateTo(&names);
    query.setQuery("doc('pages.xml')//page[name=\"Source\"]/configuration/sources/source/input/@projector/string()");
    query.evaluateTo(&projector_inputs);
    query.setQuery("doc('pages.xml')//page[name=\"Source\"]/configuration/sources/source/input/@switcher/string()");
    query.evaluateTo(&switcher_inputs);
    query.setQuery("doc('pages.xml')//page[name=\"Source\"]/configuration/sources/source/image/@source/string()");
    query.evaluateTo(&image_urls);
    if(names.count() > 0 && (names.count() != projector_inputs.count() || names.count() != switcher_inputs.count()))
    {
        //there was a problem
        qDebug() << "Problem reading XML";
    }
    else
    {
        QState *parentState = new QState();
        QState *firstState;
        for(int i = 0; i < names.count(); i++)
        {
            QState *state = new QState(parentState);
            if(i == 0)firstState = state;
            state->assignProperty(this, "state", names.at(i));
            StringTransition *t = new StringTransition(names.at(i),
                                                       projector_inputs.at(i),
                                                       switcher_inputs.at(i).toInt(),
                                                       projector, switcher);
            t->setTargetState(state);
            parentState->addTransition(t);
            nameToExtronMap[switcher_inputs.at(i).toInt()] = names.at(i);
            nameToImageMap[names.at(i)] = image_urls.at(i);
        }
        parentState->setInitialState(firstState);
        stateMachine.addState(parentState);
        stateMachine.setInitialState(parentState);
        connect(&stateMachine, SIGNAL(started()), this, SLOT(setUp()));
        stateMachine.start();
    }

    connect(switcher, SIGNAL(input_changed(uint)), this, SLOT(switcher_input_changed()));
    connect(projector, SIGNAL(power_changed(bool)), this, SLOT(projector_power_changed(bool)));

    connect(switcher, SIGNAL(connected_changed(bool)), this, SIGNAL(connectedChanged(bool)));
    //connect(projector, SIGNAL(connectedChanged(bool)), this, SIGNAL(connectedChanged(bool)));
}
void SourceController::setUp()
{
    //Call the changed slots so that we start out with the correct state
    switcher_input_changed();
    projector_input_changed(projector->input());
}

bool SourceController::connected() const
{
    return switcher->connected();// && projector->connected();
}

QString SourceController::sourceImageURL() const
{
    return nameToImageMap[this->source()];
}

QString SourceController::source() const
{
    return m_source;
}
void SourceController::setSource(QString source)
{
    stateMachine.postEvent(new StringEvent(source));
    bool changed = m_source != source;
    m_source = source;
    if(changed)emit sourceChanged();
}

QString SourceController::state() const
{
    return m_state;
}
void SourceController::setState(QString state)
{
    m_state = state;
}

void SourceController::projector_power_changed(bool on)
{
    if(on)
    {
        stateMachine.postEvent(new StringEvent(m_source));
    }
}

void SourceController::projector_input_changed(QString input)
{
}

void SourceController::switcher_input_changed()
{
    stateMachine.postEvent(new StringEvent(nameToExtronMap[switcher->input()]));
    m_source = nameToExtronMap[switcher->input()];
    emit sourceChanged();
}

