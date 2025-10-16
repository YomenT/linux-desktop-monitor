#include "sshmanager.h"
#include <QDebug>
#include <QNetworkRequest>
#include <QUrl>
#include <QFile>
#include <QFileInfo>
#include <QDir>

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

void SSHManager::shutdownDesktop(const QString &host, int port)
{
    qDebug() << "========== Shutdown Request ==========";
    qDebug() << "Host:" << host;
    qDebug() << "Port:" << port;
    
    // Build the URL
    QString url = QString("http://%1:%2/shutdown").arg(host).arg(port);
    qDebug() << "Requesting:" << url;
    
    QNetworkRequest request;
    request.setUrl(QUrl(url));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    qDebug() << "Sending HTTP GET request for shutdown...";
    
    // Create a separate handler for shutdown response
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Use a lambda to handle the shutdown response separately
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        
        qDebug() << "========== Shutdown Response Received ==========";
        
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Network error:" << reply->errorString();
            emit shutdownResult(false, "Network error: " + reply->errorString());
            return;
        }
        
        // Read response
        QByteArray data = reply->readAll();
        qDebug() << "Response data:" << data;
        
        // Parse JSON
        QJsonParseError parseError;
        QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
        
        if (parseError.error != QJsonParseError::NoError) {
            emit shutdownResult(false, "Invalid response: " + parseError.errorString());
            return;
        }
        
        QJsonObject result = doc.object();
        bool success = result.value("success").toBool();
        QString message = result.value("message").toString("Shutdown initiated");
        
        qDebug() << "Shutdown result:" << success << message;
        emit shutdownResult(success, message);
    });
}

void SSHManager::onNetworkReply(QNetworkReply *reply)
{
    qDebug() << "========== HTTP Response Received ==========";
    
    // Check if this is a metrics request (only process those here)
    QString url = reply->url().toString();
    if (!url.contains("/metrics")) {
        qDebug() << "Skipping non-metrics response in onNetworkReply:" << url;
        return;  // This reply is handled by a different handler
    }
    
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

void SSHManager::listFiles(const QString &host, int port, const QString &path)
{
    qDebug() << "========== List Files Request ==========";
    qDebug() << "Host:" << host << "Port:" << port;
    qDebug() << "Path:" << path;
    
    // Build URL with query parameter
    QString url = QString("http://%1:%2/files/list?path=%3")
        .arg(host)
        .arg(port)
        .arg(QString(QUrl::toPercentEncoding(path)));
    
    qDebug() << "Requesting:" << url;
    
    QNetworkRequest request;
    request.setUrl(QUrl(url));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        
        if (reply->error() != QNetworkReply::NoError) {
            emit fileError("Failed to list files: " + reply->errorString());
            return;
        }
        
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        
        if (!doc.isObject()) {
            emit fileError("Invalid response format");
            return;
        }
        
        QJsonObject result = doc.object();
        if (!result.value("success").toBool()) {
            emit fileError(result.value("error").toString("Unknown error"));
            return;
        }
        
        emit fileListResult(result.toVariantMap());
    });
}

void SSHManager::downloadFile(const QString &host, int port, const QString &path, const QString &savePath)
{
    qDebug() << "========== Download File Request ==========";
    qDebug() << "Host:" << host << "Port:" << port;
    qDebug() << "Remote path:" << path;
    qDebug() << "Save path:" << savePath;
    
    QString url = QString("http://%1:%2/files/download?path=%3")
        .arg(host)
        .arg(port)
        .arg(QString(QUrl::toPercentEncoding(path)));
    
    QNetworkRequest request;
    request.setUrl(QUrl(url));
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    connect(reply, &QNetworkReply::downloadProgress, this, 
            [this, path](qint64 received, qint64 total) {
        if (total > 0) {
            int progress = (int)((received * 100) / total);
            emit downloadProgress(path, progress);
        }
    });
    
    connect(reply, &QNetworkReply::finished, this, [this, reply, savePath, path]() {
        reply->deleteLater();
        
        if (reply->error() != QNetworkReply::NoError) {
            emit fileError("Download failed: " + reply->errorString());
            return;
        }
        
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        
        if (!doc.isObject()) {
            emit fileError("Invalid response format");
            return;
        }
        
        QJsonObject result = doc.object();
        if (!result.value("success").toBool()) {
            emit fileError(result.value("error").toString("Download failed"));
            return;
        }
        
        // Decode base64 data
        QString base64Data = result.value("data").toString();
        QByteArray fileData = QByteArray::fromBase64(base64Data.toUtf8());
        
        // Ensure destination directory exists
        QFileInfo saveFileInfo(savePath);
        QDir saveDir = saveFileInfo.absoluteDir();
        if (!saveDir.exists()) {
            qDebug() << "Creating directory:" << saveDir.absolutePath();
            if (!saveDir.mkpath(".")) {
                emit fileError("Failed to create directory: " + saveDir.absolutePath());
                return;
            }
        }
        
        // Save file
        QFile file(savePath);
        if (!file.open(QIODevice::WriteOnly)) {
            QString errorMsg = "Failed to save file: " + file.errorString();
            qDebug() << errorMsg;
            qDebug() << "Save path:" << savePath;
            qDebug() << "Directory exists:" << saveDir.exists();
            qDebug() << "Directory writable:" << QFileInfo(saveDir.absolutePath()).isWritable();
            emit fileError(errorMsg);
            return;
        }
        
        file.write(fileData);
        file.close();
        
        QString filename = result.value("filename").toString();
        qDebug() << "File downloaded successfully:" << filename;
        qDebug() << "Saved to:" << savePath;
        emit downloadComplete(filename, savePath);
    });
}

void SSHManager::uploadFile(const QString &host, int port, const QString &localPath, const QString &remotePath)
{
    qDebug() << "========== Upload File Request ==========";
    qDebug() << "Host:" << host << "Port:" << port;
    qDebug() << "Local path:" << localPath;
    qDebug() << "Remote path:" << remotePath;
    
    // Check if file exists
    QFileInfo fileInfo(localPath);
    if (!fileInfo.exists()) {
        QString errorMsg = "File does not exist: " + localPath;
        qDebug() << errorMsg;
        emit fileError(errorMsg);
        return;
    }
    
    qDebug() << "File exists: YES";
    qDebug() << "File size:" << fileInfo.size() << "bytes";
    qDebug() << "File is readable:" << fileInfo.isReadable();
    qDebug() << "File permissions:" << QString::number(fileInfo.permissions(), 16);
    
    // Read local file
    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly)) {
        QString errorMsg = "Failed to read file: " + file.errorString();
        qDebug() << errorMsg;
        qDebug() << "File path attempted:" << localPath;
        qDebug() << "Absolute path:" << fileInfo.absoluteFilePath();
        emit fileError(errorMsg);
        return;
    }
    
    QByteArray fileData = file.readAll();
    file.close();
    
    qDebug() << "Successfully read file, size:" << fileData.size() << "bytes";
    
    QString filename = QFileInfo(localPath).fileName();
    QString base64Data = QString(fileData.toBase64());
    
    // Build URL
    QString url = QString("http://%1:%2/files/upload?path=%3")
        .arg(host)
        .arg(port)
        .arg(QString(QUrl::toPercentEncoding(remotePath)));
    
    // Build JSON body
    QJsonObject json;
    json["filename"] = filename;
    json["data"] = base64Data;
    
    QJsonDocument doc(json);
    QByteArray jsonData = doc.toJson();
    
    QNetworkRequest request;
    request.setUrl(QUrl(url));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QNetworkReply *reply = m_networkManager->post(request, jsonData);
    
    connect(reply, &QNetworkReply::uploadProgress, this,
            [this, filename](qint64 sent, qint64 total) {
        if (total > 0) {
            int progress = (int)((sent * 100) / total);
            emit uploadProgress(filename, progress);
        }
    });
    
    connect(reply, &QNetworkReply::finished, this, [this, reply, filename]() {
        reply->deleteLater();
        
        if (reply->error() != QNetworkReply::NoError) {
            emit fileError("Upload failed: " + reply->errorString());
            return;
        }
        
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        
        if (!doc.isObject()) {
            emit fileError("Invalid response format");
            return;
        }
        
        QJsonObject result = doc.object();
        if (!result.value("success").toBool()) {
            emit fileError(result.value("error").toString("Upload failed"));
            return;
        }
        
        qDebug() << "File uploaded successfully:" << filename;
        emit uploadComplete(filename);
    });
}
