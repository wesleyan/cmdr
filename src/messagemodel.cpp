#include <QtCore/qdebug.h>
#include <QtCore/qstack.h>
#include <qmlcontext.h>
#include <qmlbindablevalue.h>
#include "messagemodel.h"
#include <QTimer>
#include <QSignalMapper>
QList<int> _roles;


MessageModel::MessageModel(QObject *parent)
: QListModelInterface(parent)
{
    _roles = QList<int>();
    _roles << 0;
}

int MessageModel::count() const
{
    return messages.count();
}

QHash<int, QVariant> MessageModel::data(int index, const QList<int> &roles) const
{
    QHash<int, QVariant> rv;

    if(index >= count())return rv;
    QHash<int, QVariant> message = messages.at(index);

    for (int i = 0; i < roles.count(); i++)
    {
        rv.insert(roles.at(i), message[roles.at(i)]);
    }

    return rv;
}

QList<int> MessageModel::roles() const
{
    return _roles;
}

QString MessageModel::toString(int role) const
{
    switch(role)
    {
        case 0:
            return "message";
    }
    return QString();
}


void MessageModel::addMessage(QString message, int timeout)
{
    QHash<int, QVariant> hash;
    hash.insert(0, QVariant(message));
    messages.append(hash);

    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    QSignalMapper *signalMapper = new QSignalMapper(this);
    signalMapper->setMapping(timer, message);
    connect(timer, SIGNAL(timeout()), signalMapper, SLOT(map()));
    timer->start(timeout);

    connect(signalMapper, SIGNAL(mapped(QString)), this, SLOT(removeMessage(QString)));
    emit itemsInserted(messages.count()-1, 1);
    emit countChanged();
}

void MessageModel::removeMessage(QString message)
{
    int i;
    for(i = 0; i < messages.count(); i++)
    {
        if(messages.at(i).value(0).toString() == message)break;
    }
    if(i < messages.count())
    {
        messages.removeAt(i);
        emit itemsRemoved(i, 1);
        emit countChanged();
    }
}
