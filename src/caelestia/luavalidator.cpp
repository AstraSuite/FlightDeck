#include "luavalidator.hpp"

#include <QProcess>
#include <QStandardPaths>
#include <QFileInfo>
#include <QDebug>
#include <QStack>

namespace Helm::Caelestia {

bool LuaValidator::validate(const QString& luaCode, QString* errorOut) {
    const QString luacPath = QStandardPaths::findExecutable(QStringLiteral("luac"));
    if (!luacPath.isEmpty()) {
        QProcess proc;
        proc.start(luacPath, QStringList{ QStringLiteral("-p"), QStringLiteral("-") });
        if (proc.waitForStarted(1000)) {
            proc.write(luaCode.toUtf8());
            proc.closeWriteChannel();
            if (proc.waitForFinished(2000)) {
                if (proc.exitCode() == 0) {
                    return true;
                }
                const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
                if (errorOut) *errorOut = err;
                return false;
            }
        }
    }

    const QString luaPath = QStandardPaths::findExecutable(QStringLiteral("lua"));
    if (!luaPath.isEmpty()) {
        QProcess proc;
        proc.start(luaPath, QStringList{ QStringLiteral("-e"), QStringLiteral("local code = io.read('*a'); local f, err = load(code); if not f then io.stderr:write(err); os.exit(1) end") });
        if (proc.waitForStarted(1000)) {
            proc.write(luaCode.toUtf8());
            proc.closeWriteChannel();
            if (proc.waitForFinished(2000)) {
                if (proc.exitCode() == 0) {
                    return true;
                }
                const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
                if (errorOut) *errorOut = err;
                return false;
            }
        }
    }

    return heuristicValidate(luaCode, errorOut);
}

bool LuaValidator::validateFile(const QString& filePath, QString* errorOut) {
    const QString luacPath = QStandardPaths::findExecutable(QStringLiteral("luac"));
    if (!luacPath.isEmpty()) {
        QProcess proc;
        proc.start(luacPath, QStringList{ QStringLiteral("-p"), filePath });
        if (proc.waitForFinished(2000)) {
            if (proc.exitCode() == 0) {
                return true;
            }
            const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
            if (errorOut) *errorOut = err;
            return false;
        }
    }
    return true;
}

bool LuaValidator::heuristicValidate(const QString& luaCode, QString* errorOut) {
    QStack<QChar> stack;
    bool inString = false;
    QChar stringChar;
    bool inComment = false;

    for (int i = 0; i < luaCode.length(); ++i) {
        const QChar c = luaCode.at(i);
        const QChar next = (i + 1 < luaCode.length()) ? luaCode.at(i + 1) : QChar();

        if (!inString && !inComment && c == QLatin1Char('-') && next == QLatin1Char('-')) {
            inComment = true;
            ++i;
            continue;
        }

        if (inComment) {
            if (c == QLatin1Char('\n')) {
                inComment = false;
            }
            continue;
        }

        if (!inString && (c == QLatin1Char('"') || c == QLatin1Char('\''))) {
            inString = true;
            stringChar = c;
            continue;
        }

        if (inString) {
            if (c == QLatin1Char('\\')) {
                ++i; // skip escaped
                continue;
            }
            if (c == stringChar) {
                inString = false;
            }
            continue;
        }

        if (c == QLatin1Char('(') || c == QLatin1Char('{') || c == QLatin1Char('[')) {
            stack.push(c);
        } else if (c == QLatin1Char(')')) {
            if (stack.isEmpty() || stack.pop() != QLatin1Char('(')) {
                if (errorOut) *errorOut = QStringLiteral("Unmatched ')' at pos %1").arg(i);
                return false;
            }
        } else if (c == QLatin1Char('}')) {
            if (stack.isEmpty() || stack.pop() != QLatin1Char('{')) {
                if (errorOut) *errorOut = QStringLiteral("Unmatched '}' at pos %1").arg(i);
                return false;
            }
        } else if (c == QLatin1Char(']')) {
            if (stack.isEmpty() || stack.pop() != QLatin1Char('[')) {
                if (errorOut) *errorOut = QStringLiteral("Unmatched ']' at pos %1").arg(i);
                return false;
            }
        }
    }

    if (inString) {
        if (errorOut) *errorOut = QStringLiteral("Unterminated string in Lua code");
        return false;
    }

    if (!stack.isEmpty()) {
        if (errorOut) *errorOut = QStringLiteral("Unclosed '%1' in Lua code").arg(stack.top());
        return false;
    }

    return true;
}

} // namespace Helm::Caelestia
