#pragma once
#include <QString>
#include <QDataStream>

// Cтруктура для отправки клиенту
struct ClientData {
    QString message;    // Текстовое сообщение
    int clientCount;    // Количество подключенных клиентов
};

// Переопределяем вывод
inline QDataStream &operator<<(QDataStream &out, const ClientData &data) {
    out << data.message << data.clientCount;
    return out;
}

// Переопределяем ввод
inline QDataStream &operator>>(QDataStream &in, ClientData &data) {
    in >> data.message >> data.clientCount;
    return in;
}