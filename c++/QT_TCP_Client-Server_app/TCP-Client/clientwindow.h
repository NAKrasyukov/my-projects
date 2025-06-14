#pragma once

#include <QWidget>
#include <QTcpSocket>    // Для подключения по TCP
#include <QLabel>        // Для отображения текста
#include <QPushButton>   // Кнопка "Подключиться"
#include <QVBoxLayout>   // Расположение элементов
#include <QDataStream>   // Поток для чтения данных из сокета

class ClientWindow : public QWidget {
    Q_OBJECT

public:
    ClientWindow(QWidget *parent = nullptr);  // Конструктор окна

private slots:
    void onConnectButtonClicked();       // Обработчик нажатия на кнопку (подключение/отключение)
    void onConnected();                  // Обработчик успешного подключения
    void onReadyRead();                  // Обработка входящих данных
    void onDisconnected();              // Обработка отключения от сервера
    void onErrorOccurred(QAbstractSocket::SocketError socketError); // Ошибка подключения

private:
    QTcpSocket *socket;
    QLabel *labelClientCount;
    QLabel *labelMessage;
    QPushButton *connectButton;

    bool isConnected = false;  // Состояние подключения
};