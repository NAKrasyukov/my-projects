QT += core gui network

greaterThan(QT_MAJOR_VERSION, 5): QT += widgets

CONFIG += c++17 console
CONFIG -= app_bundle

SOURCES += main.cpp \
           clientwindow.cpp

HEADERS += clientwindow.h