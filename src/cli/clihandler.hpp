#pragma once

#include <QCoreApplication>
#include <QStringList>

namespace Helm::Cli {

class CliHandler {
public:
    static int run(int argc, char* argv[]);
};

} // namespace Helm::Cli
