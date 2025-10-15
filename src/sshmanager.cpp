#include "sshmanager.h"
#include <QDebug>
#include <QNetworkRequest>
#include <QUrl>

SSHManager::SSHManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &SSHManager::onNetworkReply);
}

SSHManager::~SSHManager()
{
}

void SSHManager::connectToHost(const QString &host, 
                               const QString &username, 
                               const QString &password, 
                               int port)
{
    qDebug() << "========== HTTP Connection Request ==========";
    qDebug() << "Host:" << host;
    qDebug() << "Port:" << port;
    qDebug() << "Auth Token:" << (password.isEmpty() ? "None" : "Provided");
    
    // Build the URL
    QString url = QString("http://%1:%2/metrics").arg(host).arg(port);
    qDebug() << "Requesting:" << url;
    
    QNetworkRequest request;
    request.setUrl(QUrl(url));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    // Add authentication token if provided (password field is used as token)
    if (!password.isEmpty()) {
        request.setRawHeader("Authorization", QString("Bearer %1").arg(password).toUtf8());
        qDebug() << "Added authentication header";
    }
    
    qDebug() << "Sending HTTP GET request...";
    m_networkManager->get(request);
}

void SSHManager::onNetworkReply(QNetworkReply *reply)
{
    qDebug() << "========== HTTP Response Received ==========";
    
    // Ensure reply is deleted later
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        qDebug() << "Network error:" << reply->errorString();
        qDebug() << "Error code:" << reply->error();
        
        QString errorMsg;
        switch (reply->error()) {
            case QNetworkReply::ConnectionRefusedError:
                errorMsg = "Connection refused. Is the server running on your desktop?\n"
                          "Run: python3 desktop_monitor_server.py";
                break;
            case QNetworkReply::HostNotFoundError:
                errorMsg = "Host not found. Check the IP address.";
                break;
            case QNetworkReply::TimeoutError:
                errorMsg = "Connection timed out. Check your network connection.";
                break;
            case QNetworkReply::AuthenticationRequiredError:
                errorMsg = "Authentication failed. Check your token.";
                break;
            default:
                errorMsg = "Network error: " + reply->errorString();
        }
        
        emit errorOccurred(errorMsg);
        return;
    }
    
    // Read response
    QByteArray data = reply->readAll();
    qDebug() << "Response data:" << data;
    
    // Parse JSON
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
    
    if (parseError.error != QJsonParseError::NoError) {
        qDebug() << "JSON parse error:" << parseError.errorString();
        emit errorOccurred("Invalid response from server: " + parseError.errorString());
        return;
    }
    
    if (!doc.isObject()) {
        emit errorOccurred("Invalid response format");
        return;
    }
    
    QJsonObject result = doc.object();
    qDebug() << "Parsed JSON:" << result;
    
    // Check for errors in response
    if (result.contains("error")) {
        emit errorOccurred("Server error: " + result["error"].toString());
        return;
    }
    
    // Check for success
    if (!result.value("success").toBool()) {
        emit errorOccurred("Server returned unsuccessful response");
        return;
    }
    
    // Convert QJsonObject to QVariantMap for QML compatibility
    QVariantMap resultMap = result.toVariantMap();
    qDebug() << "Connection successful! Emitting result as QVariantMap";
    emit connectionResult(resultMap);
}
