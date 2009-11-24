#include <qml.h>
#include <QPixmap>
#include <QBitmap>
#include <QPoint>
#include <QDebug>
#include "inpolygondetector.h"

QML_DEFINE_TYPE(WesControl, 1, 0, 0, MaskedMouseRegion, MaskedMouseRegion);


QString MaskedMouseRegion::maskPath() const
{
    return m_maskPath;
}
void MaskedMouseRegion::setMaskPath(QString maskPath)
{
    QPixmap bm(maskPath);
    region = new QRegion(bm.mask());
    m_maskPath = maskPath;
}


void MaskedMouseRegion::saveEvent(QGraphicsSceneMouseEvent *event) {
    lastPos = event->pos();
    lastButton = event->button();
    lastButtons = event->buttons();
    lastModifiers = event->modifiers();
}


MaskedMouseRegion::MaskedMouseRegion(QmlGraphicsItem *parent)
  : QmlGraphicsItem(parent)
{
        this->setAcceptedMouseButtons(Qt::LeftButton);

}

MaskedMouseRegion::~MaskedMouseRegion()
{
}

qreal MaskedMouseRegion::mouseX() const
{
    return lastPos.x();
}

qreal MaskedMouseRegion::mouseY() const
{
    return lastPos.y();
}

bool MaskedMouseRegion::isEnabled() const
{
    return absorb;
}

void MaskedMouseRegion::setEnabled(bool a)
{
    if (a != absorb) {
        absorb = a;
        emit enabledChanged();
    }
}

Qt::MouseButtons MaskedMouseRegion::pressedButtons() const
{
    return lastButtons;
}

void MaskedMouseRegion::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if(region->contains(event->pos().toPoint()))
    {
        moved = false;
        if (absorb)
            QmlGraphicsItem::mousePressEvent(event);
        else {
            longPress = false;
            saveEvent(event);
            start = event->pos();
            startScene = event->scenePos();
            // we should only start timer if pressAndHold is connected to.
            setKeepMouseGrab(false);
            event->setAccepted(setPressed(true));
        }
    }
    else
    {
        event->ignore();
    }
}

void MaskedMouseRegion::mouseMoveEvent(QGraphicsSceneMouseEvent *event)
{
    if (!absorb) {
        QmlGraphicsItem::mouseMoveEvent(event);
        return;
    }

    saveEvent(event);

    // ### we should skip this if these signals aren't used
    // ### can GV handle this for us?
    bool contains = boundingRect().contains(lastPos);
    moved = true;
    QmlGraphicsMouseEvent me(lastPos.x(), lastPos.y(), lastButton, lastButtons, lastModifiers, false, longPress);
    emit positionChanged(&me);
}


void MaskedMouseRegion::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
    if (!absorb) {
        QmlGraphicsItem::mouseReleaseEvent(event);
    } else {
        saveEvent(event);
        setPressed(false);
        // If we don't accept hover, we need to reset containsMouse.
        setKeepMouseGrab(false);
    }
}

void MaskedMouseRegion::mouseDoubleClickEvent(QGraphicsSceneMouseEvent *event)
{
    if (!absorb) {
        QmlGraphicsItem::mouseDoubleClickEvent(event);
    } else {
        QmlGraphicsItem::mouseDoubleClickEvent(event);
        if (event->isAccepted()) {
            // Only deliver the event if we have accepted the press.
            saveEvent(event);
            QmlGraphicsMouseEvent me(lastPos.x(), lastPos.y(), lastButton, lastButtons, lastModifiers, true, false);
            emit this->doubleClicked(&me);
        }
    }
}

bool MaskedMouseRegion::sceneEvent(QEvent *event)
{
    bool rv = QmlGraphicsItem::sceneEvent(event);
    if (event->type() == QEvent::UngrabMouse) {
        if (m_pressed) {
            // if our mouse grab has been removed (probably by Flickable), fix our
            // state
            m_pressed = false;
            setKeepMouseGrab(false);
            emit pressedChanged();
            //emit hoveredChanged();
        }
    }
    return rv;
}

void MaskedMouseRegion::timerEvent(QTimerEvent *event)
{
    if (event->timerId() == pressAndHoldTimer.timerId()) {
        pressAndHoldTimer.stop();
        if (m_pressed) {
            longPress = true;
            QmlGraphicsMouseEvent me(lastPos.x(), lastPos.y(), lastButton, lastButtons, lastModifiers, false, longPress);
            emit pressAndHold(&me);
        }
    }
}


bool MaskedMouseRegion::pressed() const
{
    return m_pressed;
}


Qt::MouseButtons MaskedMouseRegion::acceptedButtons() const
{
    return acceptedMouseButtons();
}

void MaskedMouseRegion::setAcceptedButtons(Qt::MouseButtons buttons)
{
    if (buttons != acceptedMouseButtons()) {
        setAcceptedMouseButtons(buttons);
        emit acceptedButtonsChanged();
    }
}

bool MaskedMouseRegion::setPressed(bool p)
{
    bool isclick = m_pressed == true && p == false;

    if (m_pressed != p) {
        m_pressed = p;
        QmlGraphicsMouseEvent me(lastPos.x(), lastPos.y(), lastButton, lastButtons, lastModifiers, isclick, longPress);
        if (m_pressed) {
            emit positionChanged(&me);
            emit pressed(&me);
        } else {
            emit released(&me);
            if (isclick)
                emit clicked(&me);
        }

        emit pressedChanged();
        return me.isAccepted();
    }
    return false;
}

