#ifndef SSHMANAGER_H
#define SSHMANAGER_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>

class SSHManager : public QObject
{
    Q_OBJECT

public:
    explicit SSHManager(QObject *parent = nullptr);
    ~SSHManager();

    Q_INVOKABLE void connectToHost(const QString &host, 
                                   const QString &username, 
                                   const QString &password, 
                                   int port = 8080);

signals:
    void connectionResult(const QVariantMap &result);
    void errorOccurred(const QString &error);

private slots:
    void onNetworkReply(QNetworkReply *reply);

private:
    QNetworkAccessManager *m_networkManager;
};

#endif // SSHMANAGER_H
