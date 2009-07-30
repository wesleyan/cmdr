#include <qfxview.h>

#include "wescontrol.h"
#include "sourcecontroller.h"

#include <QtDeclarative/qmlcontext.h>
#include "qml.h"

#include <QSignalMapper>
#include <QmlComponent>
#include <QWidget>
#include <QApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QVBoxLayout>
#include <QProgressDialog>
#include <QProcess>
#include <QAction>
#include <QDebug>
#include <QKeyEvent>

#include <QCoreApplication>
#include <QmlEngine>
#include <QmlComponent>
#include <QDebug>


WesControl::WesControl(QWidget *parent, Qt::WindowFlags flags)
    : QWidget(parent, flags)
{
    canvas = new QFxView(this);
    canvas->setAttribute(Qt::WA_OpaquePaintEvent);
    canvas->setAttribute(Qt::WA_NoSystemBackground);
    canvas->setContentResizable(true);

    //QObject::connect(canvas, SIGNAL(sceneResized(QSize)), this, SLOT(sceneResized(QSize)));

    QVBoxLayout *layout = new QVBoxLayout;
    layout->setMargin(0);
    layout->setSpacing(0);
    setLayout(layout);

    layout->addWidget(canvas);

}

void WesControl::openQml(const QString& fileName)
{
    setWindowTitle("WesControl 0.1");

    canvas->reset();

    currentFileName = fileName;
    QUrl url(fileName);
    QFileInfo fi(fileName);
    if (fi.exists()) {
            url = QUrl::fromLocalFile(fi.absoluteFilePath());
            QmlContext *ctxt = canvas->rootContext();
            QDir dir(fi.path()+"/dummydata", "*.qml");
            QStringList list = dir.entryList();
            for (int i = 0; i < list.size(); ++i) {
                QString qml = list.at(i);
                QFile f(dir.filePath(qml));
                f.open(QIODevice::ReadOnly);
                QByteArray data = f.readAll();
                QmlComponent comp(canvas->engine());
                comp.setData(data, QUrl());
                QObject *dummyData = comp.create();

                if(comp.isError()) {
                    QList<QmlError> errors = comp.errors();
                    foreach (const QmlError &error, errors) {
                        qWarning() << error;
                    }
                }

                if (dummyData) {
                    qWarning() << "Loaded dummy data:" << dir.filePath(qml);
                    qml.truncate(qml.length()-4);
                    ctxt->setContextProperty(qml, dummyData);
                    dummyData->setParent(this);
                }
            }
    }

    canvas->setUrl(url);
    QTime t;
    t.start();

    messages = new MessageModel;
    SourceController *sourcecontroller = new SourceController;
    //connect(projector, SIGNAL(sendMessage(QString,int)), messages, SLOT(addMessage(QString,int)));

    QmlContext *ctxt = canvas->rootContext();
    //ctxt->setContextProperty("projector", projector);
    ctxt->setContextProperty("messages", messages);
    ctxt->setContextProperty("sourcecontroller", sourcecontroller);

    canvas->execute();
    qWarning() << "Wall startup time:" << t.elapsed();
    //projector->updateVariables();

    canvas->resize(canvas->sizeHint());
    resize(sizeHint());

}

void WesControl::reload()
{
    openQml(currentFileName);
}

void WesControl::keyPressEvent(QKeyEvent *event)
{
    if (event->key() == Qt::Key_F5 || (event->key() == Qt::Key_R && event->modifiers() == Qt::ControlModifier)) {
        reload();
    }
    if(event->key() == Qt::Key_F6)
    {
        messages->addMessage("Oh noes! This is a message", 5000);
    }
    if(event->key() == Qt::Key_Q && event->modifiers() == Qt::ControlModifier)
    {
        emit quit();
    }

    QWidget::keyPressEvent(event);
}

int main(int argc, char *argv[])
{
    QApplication::setGraphicsSystem("raster");
    qDebug() << "Starting";
    QApplication app(argc, argv);
    app.setApplicationName("wescontrol");

    bool frameless = false;

    app.setOverrideCursor(QCursor(Qt::BlankCursor));
    for(int i = 0; i < argc; i++)
    {
        if(QString(argv[i]).contains("-showcursor", Qt::CaseInsensitive))
        {
            app.setOverrideCursor(QCursor(Qt::OpenHandCursor));
        }
        else if(QString(argv[i]).contains("-frameless", Qt::CaseInsensitive))
        {
            frameless = true;
        }
    }
    qDebug() << "Starting";

    QString fileName = "qml/wescontrol.qml";

    QString testDir;

    WesControl viewer(0, frameless ? Qt::FramelessWindowHint : Qt::Widget);
    QObject::connect(&viewer, SIGNAL(quit()), &app, SLOT(quit()));
    //foreach (QString lib, libraries)
    //viewer.addLibraryPath(lib);
    qDebug() << "Starting";

    viewer.openQml(fileName);
    viewer.show();
    qDebug() << "Starting4";

    return app.exec();
}
