#pragma once

#include <QTcpServer>
#include <QTcpSocket>
#include <QSet> 

class TcpServer : public QTcpServer {
    Q_OBJECT

    public:
        // создание класса в qt
        explicit TcpServer(QObject *parent = nullptr);

    protected:
        // Переопределяем метод, вызываемый при новом подключении
        void incomingConnection(qintptr socketDescriptor) override;

    private:
        // Храним список всех подключенных клиентов
        QSet<QTcpSocket*> clients;

        // Отправка структуры ClientData клиенту
        void sendClientData(QTcpSocket *socket);

        // Удаление клиента при отключении
        void removeClient(QTcpSocket *socket);

        // Отправка структуры ClientData всем подключенным клиентам 
        void sendClientCountToAll(const QString &message);
};