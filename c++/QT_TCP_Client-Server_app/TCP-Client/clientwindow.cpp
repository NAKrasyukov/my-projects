#include "clientwindow.h"

ClientWindow::ClientWindow(QWidget *parent)
    : QWidget(parent), socket(new QTcpSocket(this))
{
    // Инициализация виджетов
    labelClientCount = new QLabel("Клиентов подключено: —");
    labelMessage = new QLabel("Статус: ожидание подключения...");
    connectButton = new QPushButton("Подключиться");

    // Установка layout
    auto *layout = new QVBoxLayout(this);
    layout->addWidget(labelClientCount);
    layout->addWidget(labelMessage);
    layout->addWidget(connectButton);

    // Соединяем сигналы сокета со слотами
    connect(connectButton, &QPushButton::clicked, this, &ClientWindow::onConnectButtonClicked);
    connect(socket, &QTcpSocket::connected, this, &ClientWindow::onConnected);
    connect(socket, &QTcpSocket::readyRead, this, &ClientWindow::onReadyRead);
    connect(socket, &QTcpSocket::disconnected, this, &ClientWindow::onDisconnected);
    connect(socket, &QTcpSocket::errorOccurred, this, &ClientWindow::onErrorOccurred);
}

void ClientWindow::onConnectButtonClicked() {
    if (!isConnected) {
        // Подключаемся к серверу
        labelMessage->setText("Подключение к серверу...");
        socket->connectToHost("127.0.0.1", 1234);
    } else {
        // Отключаемся от сервера
        socket->disconnectFromHost();
        labelMessage->setText("Отключено от сервера.");
    }
}

void ClientWindow::onConnected() {
    isConnected = true;

    // Обновляем интерфейс
    labelMessage->setText("Успешно подключено к серверу");
    connectButton->setText("Отключиться");
}

void ClientWindow::onDisconnected() {
    isConnected = false;

    // Сброс состояния и интерфейса
    labelMessage->setText("Отключено от сервера");
    connectButton->setText("Подключиться");
    labelClientCount->setText("Клиентов подключено: —");
}

void ClientWindow::onErrorOccurred(QAbstractSocket::SocketError socketError) {
    Q_UNUSED(socketError);

    // Если не удалось подключиться
    if (!isConnected) {
        labelMessage->setText("Ошибка: сервер не обнаружен");
    }

    // Отключаем сокет явно, чтобы сбросить его состояние
    socket->abort();
    isConnected = false;
    connectButton->setText("Подключиться");
}

void ClientWindow::onReadyRead() {
    QDataStream in(socket);
    in.setVersion(QDataStream::Qt_6_0);

    QString message;
    int clientCount;

    in >> message >> clientCount;

    labelMessage->setText("Сообщение: " + message);
    labelClientCount->setText("Клиентов подключено: " + QString::number(clientCount));
}