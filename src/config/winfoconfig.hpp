#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class WInfoConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

public:
    explicit WInfoConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

}
