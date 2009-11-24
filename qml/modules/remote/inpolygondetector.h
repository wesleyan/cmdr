#include <QObject>
#include <QtDeclarative/qmlcontext.h>
#include <QtDeclarative/qmlengine.h>
#include <QPoint>
#include <QRegion>
#include <QmlGraphicsItem>
#include <QtGui/qevent.h>
#include "qdatetime.h"
#include "qbasictimer.h"
#include "qgraphicssceneevent.h"

#ifndef MaskedMouseRegion_H
#define MaskedMouseRegion_H

class QmlGraphicsMouseEvent : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int x READ x)
    Q_PROPERTY(int y READ y)
    Q_PROPERTY(int button READ button)
    Q_PROPERTY(int buttons READ buttons)
    Q_PROPERTY(int modifiers READ modifiers)
    Q_PROPERTY(bool wasHeld READ wasHeld)
    Q_PROPERTY(bool isClick READ isClick)
    Q_PROPERTY(bool accepted READ isAccepted WRITE setAccepted)

public:
    QmlGraphicsMouseEvent(int x, int y, Qt::MouseButton button, Qt::MouseButtons buttons, Qt::KeyboardModifiers modifiers
                  , bool isClick=false, bool wasHeld=false)
        : _x(x), _y(y), _button(button), _buttons(buttons), _modifiers(modifiers)
          , _wasHeld(wasHeld), _isClick(isClick), _accepted(true) {}

    int x() const { return _x; }
    int y() const { return _y; }
    int button() const { return _button; }
    int buttons() const { return _buttons; }
    int modifiers() const { return _modifiers; }
    bool wasHeld() const { return _wasHeld; }
    bool isClick() const { return _isClick; }

    bool isAccepted() { return _accepted; }
    void setAccepted(bool accepted) { _accepted = accepted; }

private:
    int _x;
    int _y;
    Qt::MouseButton _button;
    Qt::MouseButtons _buttons;
    Qt::KeyboardModifiers _modifiers;
    bool _wasHeld;
    bool _isClick;
    bool _accepted;
};


class Q_DECLARATIVE_EXPORT MaskedMouseRegion : public QmlGraphicsItem
{
    Q_OBJECT

    Q_PROPERTY(qreal mouseX READ mouseX NOTIFY positionChanged)
    Q_PROPERTY(qreal mouseY READ mouseY NOTIFY positionChanged)
    Q_PROPERTY(bool containsMouse READ hovered NOTIFY hoveredChanged)
    Q_PROPERTY(bool pressed READ pressed NOTIFY pressedChanged)
    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(Qt::MouseButtons pressedButtons READ pressedButtons NOTIFY pressedChanged)
    Q_PROPERTY(Qt::MouseButtons acceptedButtons READ acceptedButtons WRITE setAcceptedButtons NOTIFY acceptedButtonsChanged)
    Q_PROPERTY(QmlGraphicsDrag *drag READ drag) //### add flicking to QmlGraphicsDrag or add a QmlGraphicsFlick ???
    Q_PROPERTY(QString maskPath READ maskPath WRITE setMaskPath);

public:
    MaskedMouseRegion(QmlGraphicsItem *parent=0);
    ~MaskedMouseRegion();

    QString maskPath() const;
    void setMaskPath(QString);

    qreal mouseX() const;
    qreal mouseY() const;

    bool isEnabled() const;
    void setEnabled(bool);

    bool pressed() const;

    Qt::MouseButtons pressedButtons() const;

    Qt::MouseButtons acceptedButtons() const;
    void setAcceptedButtons(Qt::MouseButtons buttons);

    void saveEvent(QGraphicsSceneMouseEvent *event);


Q_SIGNALS:
    void hoveredChanged();
    void pressedChanged();
    void enabledChanged();
    void acceptedButtonsChanged();
    void positionChanged(QmlGraphicsMouseEvent *mouse);

    void pressed(QmlGraphicsMouseEvent *mouse);
    void pressAndHold(QmlGraphicsMouseEvent *mouse);
    void released(QmlGraphicsMouseEvent *mouse);
    void clicked(QmlGraphicsMouseEvent *mouse);
    void doubleClicked(QmlGraphicsMouseEvent *mouse);
    void entered();
    void exited();

protected:
    void setHovered(bool);
    bool setPressed(bool);

    void mousePressEvent(QGraphicsSceneMouseEvent *event);
    void mouseReleaseEvent(QGraphicsSceneMouseEvent *event);
    void mouseDoubleClickEvent(QGraphicsSceneMouseEvent *event);
    void mouseMoveEvent(QGraphicsSceneMouseEvent *event);
    bool sceneEvent(QEvent *);
    void timerEvent(QTimerEvent *event);

private:
    void handlePress();
    void handleRelease();
    QRegion *region;
    QString m_maskPath;
    bool absorb;
    bool m_pressed;
    bool longPress;
    bool moved;
    QPointF start;
    QPointF startScene;
    qreal startX;
    qreal startY;
    QPointF lastPos;
    Qt::MouseButton lastButton;
    Qt::MouseButtons lastButtons;
    Qt::KeyboardModifiers lastModifiers;
    QBasicTimer pressAndHoldTimer;


};
QML_DECLARE_TYPE(MaskedMouseRegion);

#endif // MaskedMouseRegion_H
