#pragma once

#include <QCoreApplication>
#include <QStringList>

namespace FlightDeck::Cli {

class CliHandler {
public:
    static int run(int argc, char* argv[]);
};

} // namespace FlightDeck::Cli
