#include "qttcpserver.h"
#include "clientdata.h"

#include <QDataStream>
#include <QDebug>

TcpServer::TcpServer(QObject *parent)
    : QTcpServer(parent) {}  // Просто передаём родительский объект

// Этот метод вызывается автоматически, когда к серверу подключается клиент
void TcpServer::incomingConnection(qintptr socketDescriptor) {
    // Создаем сокет, привязанный к текущему серверу
    QTcpSocket *clientSocket = new QTcpSocket(this);

    // Подключаем сокет к уже принятому соединению
    if (!clientSocket->setSocketDescriptor(socketDescriptor)) {
        qWarning() << "Ne udalos zpustit deskriptor soketa";
        clientSocket->deleteLater();
        return;
    }

    // Добавляем сокет в список клиентов
    clients.insert(clientSocket);
    qDebug() << "Noviy klient podkluchilsya. Vsego podklucheniy:" << clients.size();

    // Отправка клиенту структуры с текущим количеством подключений
    //sendClientData(clientSocket);

    // Когда клиент отключается, удаляется из списка
    connect(clientSocket, &QTcpSocket::disconnected, this, [this, clientSocket]() {
        removeClient(clientSocket);
    });

    // Рассылка всем актуального количества клиентов
    sendClientCountToAll("Новый клиент подключился!");

}

// Отправка данных клиенту
void TcpServer::sendClientData(QTcpSocket *socket) {

    ClientData data;
    data.message = "Соединение с сервером установлено!";
    data.clientCount = clients.size();

    // Сериализация структуры в QByteArray
    QByteArray block;
    QDataStream out(&block, QIODevice::WriteOnly);
    out.setVersion(QDataStream::Qt_6_0);  // версия формата сериализации

    out << data;

    // Отправляем данные в сокет
    socket->write(block);
    socket->flush();
}

// Отправка всем клиентам
void TcpServer::sendClientCountToAll(const QString &message) {
    ClientData data;
    data.message = message;
    data.clientCount = clients.size();

    // Сериализация структуры в QByteArray
    QByteArray block;
    QDataStream out(&block, QIODevice::WriteOnly);
    out.setVersion(QDataStream::Qt_6_0);  // версия формата сериализации

    out << data;

    // Рассылаем всем клиентам
    for (QTcpSocket *socket : clients) {
        socket->write(block);
        socket->flush();
    }
}

// Удаление клиента
void TcpServer::removeClient(QTcpSocket *socket) {

    if (clients.remove(socket)) {
        qDebug() << "Klient otkluchilsya. Ostalos podklucheniy:" << clients.size();
        socket->deleteLater();

        // Рассылка всем актуального количества клиентов
        sendClientCountToAll("Старый клиент отключился!");
    }
}