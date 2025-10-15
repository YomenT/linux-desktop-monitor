#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <QQmlError>
#include <QDebug>
#include <QDir>
#include "sshmanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qDebug() << "Starting Linux Desktop Monitor...";

    // Create SSHManager instance
    SSHManager *sshManager = new SSHManager();
    qDebug() << "SSHManager created:" << sshManager;
    
    // Create QQuickView
    QQuickView *view = new QQuickView();
    
    // Expose SSHManager to QML as a context property BEFORE loading QML
    view->rootContext()->setContextProperty("sshManager", sshManager);
    qDebug() << "Context property 'sshManager' set";
    
    // Get the application directory path
    QString appPath = QCoreApplication::applicationDirPath();
    QString qmlPath = appPath + "/qml/Main.qml";
    
    qDebug() << "App path:" << appPath;
    qDebug() << "Loading QML from:" << qmlPath;
    qDebug() << "QML file exists:" << QFile::exists(qmlPath);
    
    // Load the main QML file
    view->setSource(QUrl::fromLocalFile(qmlPath));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    
    if (view->status() == QQuickView::Error) {
        qCritical() << "Failed to load QML file";
        qCritical() << "Errors:" << view->errors();
        return -1;
    }
    
    qDebug() << "QML loaded successfully, showing window...";
    view->show();
    qDebug() << "Window shown";

    return app.exec();
}
