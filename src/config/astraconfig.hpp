#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class AstraConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, wallpapersPerRow, 4)
    CONFIG_PROPERTY(int, maxNetworksShown, 5)
    CONFIG_GLOBAL_PROPERTY(int, networkRescanInterval, 15000)

public:
    explicit AstraConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

}
