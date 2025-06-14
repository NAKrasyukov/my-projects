#include <QCoreApplication>
#include "qttcpserver.h"

int main(int argc, char *argv[]) {
    QCoreApplication a(argc, argv);  // Создаем консольное приложение

    TcpServer server;
    
    if (!server.listen(QHostAddress::Any, 1234)) {
        qCritical() << "Ne udalos zapustit server:" << server.errorString();
        return 1;
    }

    qDebug() << "Server zpushen na portu:" << server.serverPort();
    return a.exec();  // Запуск главного цикла приложения
}