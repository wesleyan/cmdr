#ifndef QFXDROPDOWN_H
#define QFXDROPDOWN_H

#include <QFxPaintedItem>

class QFxDropdown : public QFxPaintedItem
{
Q_OBJECT
Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged);
public:
    QFxDropdown(QFxItem * parent = 0);
    QString text() const;
    void setText(QString text);

signals:
    void textChanged();

protected:
    void drawContents(QPainter *p, const QRect &);

private:
    QString m_text;
};

QML_DECLARE_TYPE(QFxDropdown);


#endif // QFXDROPDOWN_H
