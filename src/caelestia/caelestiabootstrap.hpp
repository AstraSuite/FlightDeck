#pragma once

#include <QObject>
#include <QString>

namespace Helm::Caelestia {

class CaelestiaBootstrap : public QObject {
    Q_OBJECT

public:
    static void ensureAstraHelmSourced();
};

} // namespace Helm::Caelestia
