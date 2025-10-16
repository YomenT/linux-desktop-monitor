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
    
    Q_INVOKABLE void shutdownDesktop(const QString &host, int port = 8080);
    
    Q_INVOKABLE void listFiles(const QString &host, int port, const QString &path);
    Q_INVOKABLE void downloadFile(const QString &host, int port, const QString &path, const QString &savePath);
    Q_INVOKABLE void uploadFile(const QString &host, int port, const QString &localPath, const QString &remotePath);

signals:
    void connectionResult(const QVariantMap &result);
    void errorOccurred(const QString &error);
    void shutdownResult(bool success, const QString &message);
    void fileListResult(const QVariantMap &result);
    void downloadProgress(const QString &filename, int progress);
    void downloadComplete(const QString &filename, const QString &savePath);
    void uploadProgress(const QString &filename, int progress);
    void uploadComplete(const QString &filename);
    void fileError(const QString &error);

private slots:
    void onNetworkReply(QNetworkReply *reply);

private:
    QNetworkAccessManager *m_networkManager;
};

#endif // SSHMANAGER_H
