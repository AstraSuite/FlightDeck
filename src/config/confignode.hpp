#pragma once

#include <qjsonvalue.h>
#include <qloggingcategory.h>
#include <qmap.h>
#include <qobject.h>
#include <qstringlist.h>
#include <qtimer.h>
#include <qvariant.h>

namespace caelestia::config {

Q_DECLARE_LOGGING_CATEGORY(lcConfig)

class ConfigNode : public QObject {
    Q_OBJECT

public:
    explicit ConfigNode(QObject* parent = nullptr);

    virtual void loadFromJson(const QJsonValue& json) = 0;

    void loadFromJsonQuietly(const QJsonValue& json);

    [[nodiscard]] virtual QJsonValue toJson() const = 0;

    virtual void clearLoadedKeys() = 0;

    [[nodiscard]] virtual QStringList unknownKeys() const = 0;

    [[nodiscard]] virtual QList<ConfigNode*> childNodes() const;

    void syncFromGlobal(ConfigNode* global);
    virtual void resyncFromGlobal() = 0;

    [[nodiscard]] bool isOverlay() const;
    [[nodiscard]] QString propertyPath(const QString& name = {}) const;

    [[nodiscard]] static int basePropertyOffset();

signals:
    void propertiesChanged(const QMap<QString, QVariant>& changed);

protected:
    virtual void syncValuesFromGlobal() = 0;
    virtual void onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) = 0;

    [[nodiscard]] virtual QString childPath(const ConfigNode* child) const = 0;

    void notifyPropertyChanged(const QString& name, const QVariant& value);

    [[nodiscard]] static QString joinPath(const QString& parent, const QString& child);

    ConfigNode* m_global = nullptr;

private:
    void setNotifySuppressed(bool suppressed);
    void emitBatchedChanges();

    QMap<QString, QVariant> m_pendingChanges;
    QTimer* m_batchTimer = nullptr;
    bool m_suppressNotify = false;
};

}
