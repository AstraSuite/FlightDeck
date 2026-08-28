#pragma once

#include <QHash>
#include <QMutex>
#include <QQuickImageProvider>
#include <QStringList>

class IconImageProvider : public QQuickImageProvider {
public:
    IconImageProvider();

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;

private:
    void indexIcons();
    QString resolvePath(const QString& name);

    QHash<QString, QString> m_iconMap;
    bool m_indexed{false};
    QMutex m_mutex;
};
