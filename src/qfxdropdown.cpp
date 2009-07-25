#include "qfxdropdown.h"
#include <QDebug>

QML_DEFINE_TYPE(QFxDropdown, Dropdown);

QFxDropdown::QFxDropdown(QFxItem *parent) : QFxPaintedItem(parent)
{
    qDebug() << "Creating dropdown";
}


void QFxDropdown::setText(QString text)
{
    if(text != m_text)emit textChanged();
    m_text = text;
    qDebug() << "Text set to " << text;
}

QString QFxDropdown::text() const
{
    return m_text;
}

void QFxDropdown::drawContents(QPainter *p, const QRect &rect)
{
        p->drawText(rect, Qt::AlignCenter, m_text);
}
