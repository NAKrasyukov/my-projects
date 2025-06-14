QT += core network
CONFIG += console
CONFIG -= app_bundle
TEMPLATE = app

SOURCES += main.cpp \
           tcpserver.cpp

HEADERS += qttcpserver.h \
           clientdata.h
           