#pragma once

#include <QObject>
#include <QString>

namespace FlightDeck::Caelestia {

class CaelestiaBootstrap : public QObject {
    Q_OBJECT

public:
    static void ensureAstraHelmSourced();
};

} // namespace FlightDeck::Caelestia
