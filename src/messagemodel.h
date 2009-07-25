#include <QtCore/QObject>
#include <QtCore/QStringList>
#include <QtCore/QHash>
#include <QtCore/QList>
#include <QtCore/QVariant>
#include <QtDeclarative/qfxglobal.h>
#include <QtDeclarative/qml.h>
#include <QtDeclarative/qlistmodelinterface.h>

#ifndef MESSAGEMODEL_H
#define MESSAGEMODEL_H

class MessageModel : public QListModelInterface
{
    Q_OBJECT
public:
    MessageModel(QObject *parent=0);
    virtual QList<int> roles() const;
    virtual QString toString(int role) const;

    Q_PROPERTY(int count READ count NOTIFY countChanged);
    virtual int count() const;
    virtual QHash<int,QVariant> data(int index, const QList<int> &roles = (QList<int>())) const;

signals:
    void countChanged();

public slots:
    void addMessage(QString message, int timeout);
    void removeMessage(QString message);

private:
    QList<QHash<int, QVariant> > messages;
};




#endif // MESSAGEMODEL_H
