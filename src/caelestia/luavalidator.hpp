#pragma once

#include <QString>
#include <QObject>

namespace FlightDeck::Caelestia {

class LuaValidator {
public:
    static bool validate(const QString& luaCode, QString* errorOut = nullptr);
    static bool validateFile(const QString& filePath, QString* errorOut = nullptr);

private:
    static bool heuristicValidate(const QString& luaCode, QString* errorOut = nullptr);
};

} // namespace FlightDeck::Caelestia
