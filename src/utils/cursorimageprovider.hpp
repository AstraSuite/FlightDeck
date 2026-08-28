#pragma once

#include <QQuickImageProvider>
#include "../managers/cursormanager.hpp"

class CursorImageProvider : public QQuickImageProvider {
public:
    CursorImageProvider() : QQuickImageProvider(QQuickImageProvider::Image) {}

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override {
        int targetSize = (requestedSize.width() > 0) ? requestedSize.width() : 48;
        QImage img = Helm::Managers::CursorManager::loadCursorPreview(id, targetSize);
        if (size) {
            *size = img.size();
        }
        return img;
    }
};
