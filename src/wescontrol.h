/****************************************************************************
**
** Copyright (C) 1992-$THISYEAR$ $TROLLTECH$. All rights reserved.
**
** This file is part of the $MODULE$ of the Qt Toolkit.
**
** $TROLLTECH_DUAL_LICENSE$
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
****************************************************************************/

#ifndef QMLVIEWER_H
#define QMLVIEWER_H

#include <QBasicTimer>
#include <QTime>
#include <qfxtestengine.h>
#include <QList>
#include <QWidget>
#include "messagemodel.h"


class QFxView;
class QFxTestEngine;
class QProcess;

class WesControl : public QWidget
{
Q_OBJECT
public:
    WesControl(QWidget *parent=0, Qt::WindowFlags flags=0);

    void setCacheEnabled(bool);
    void addLibraryPath(const QString& lib);

    void doNotExportToDBus();

signals:
    void quit();

public slots:
    //void sceneResized(QSize size);
    void openQml(const QString& fileName);
    void reload();

protected:
    virtual void keyPressEvent(QKeyEvent *);

private:
    QString currentFileName;
    QFxView *canvas;
    void init(const QString &, const QString& fileName);
    MessageModel *messages;

};

#endif
