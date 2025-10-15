/*
 * Copyright (C) 2025  Yomen Tohmaz
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * linux-desktop-monitor is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Ubuntu.Components.Popups 1.3

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'linux-desktop-monitor.com.bluebird-documentation.linux-desktop-monitor'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    // Settings to persist connection details
    Settings {
        id: settings
        property string hostname: ""
        property string username: ""
        property int port: 22
    }

    PageStack {
        id: pageStack
        
        Component.onCompleted: push(connectionPage)

        Page {
            id: connectionPage
            visible: false
            
            header: PageHeader {
                id: header
                title: i18n.tr('Connect to Desktop')
            }

            Flickable {
                anchors {
                    top: header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: units.gu(2)
                }
                contentHeight: contentColumn.height
                
                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: units.gu(2)

                    // Connection Form
                    Label {
                        text: i18n.tr('Desktop Server Settings')
                        fontSize: "large"
                        font.bold: true
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr('First, start the server on your desktop:\npython3 desktop_monitor_server.py')
                        fontSize: "small"
                        color: theme.palette.normal.backgroundSecondaryText
                    }

                    TextField {
                        id: hostnameField
                        width: parent.width
                        placeholderText: i18n.tr('Desktop IP address (e.g., 192.168.1.100)')
                        text: settings.hostname
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                    }

                    TextField {
                        id: usernameField
                        width: parent.width
                        placeholderText: i18n.tr('Auth Token (optional)')
                        text: settings.username
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                        visible: false  // Hide for now, can enable if user adds token
                    }

                    TextField {
                        id: passwordField
                        width: parent.width
                        placeholderText: i18n.tr('Auth Token (optional, leave empty if not set)')
                        echoMode: TextInput.Normal
                    }

                    TextField {
                        id: portField
                        width: parent.width
                        placeholderText: i18n.tr('Port (default: 8080)')
                        text: settings.port || 8080
                        inputMethodHints: Qt.ImhDigitsOnly
                    }

                    Button {
                        width: parent.width
                        text: i18n.tr('📖 Setup Instructions')
                        color: theme.palette.normal.base
                        onClicked: pageStack.push(setupPage)
                    }

                    Button {
                        width: parent.width
                        text: i18n.tr('Connect')
                        color: theme.palette.normal.positive
                        enabled: hostnameField.text !== "" &&
                                !connectActivity.running
                        
                        onClicked: {
                            console.log("Connect button clicked")
                            console.log("Hostname:", hostnameField.text)
                            console.log("Username:", usernameField.text)
                            console.log("Password length:", passwordField.text.length)
                            
                            // Save settings
                            settings.hostname = hostnameField.text
                            settings.username = usernameField.text
                            settings.port = portField.text || 22
                            
                            // Attempt connection
                            connectToDesktop()
                        }
                    }

                    ActivityIndicator {
                        id: connectActivity
                        anchors.horizontalCenter: parent.horizontalCenter
                        running: false
                    }

                    Label {
                        id: statusLabel
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        color: theme.palette.normal.activity
                    }

                    // Log display section
                    Rectangle {
                        width: parent.width
                        height: units.gu(20)
                        color: theme.palette.normal.background
                        border.color: theme.palette.normal.base
                        border.width: units.dp(1)
                        radius: units.gu(1)

                        Column {
                            anchors.fill: parent
                            anchors.margins: units.gu(1)
                            spacing: units.gu(0.5)

                            Row {
                                width: parent.width
                                spacing: units.gu(1)

                                Label {
                                    text: i18n.tr('Debug Logs')
                                    fontSize: "small"
                                    font.bold: true
                                }

                                Button {
                                    text: i18n.tr('Clear')
                                    height: units.gu(3)
                                    width: units.gu(8)
                                    onClicked: logModel.clear()
                                }
                            }

                            ScrollView {
                                width: parent.width
                                height: parent.height - units.gu(4)

                                ListView {
                                    id: logView
                                    model: logModel
                                    clip: true
                                    
                                    delegate: Label {
                                        width: logView.width
                                        text: timestamp + " - " + message
                                        fontSize: "x-small"
                                        wrapMode: Text.Wrap
                                        color: {
                                            if (logType === "error") return theme.palette.normal.negative
                                            if (logType === "success") return theme.palette.normal.positive
                                            return theme.palette.normal.baseText
                                        }
                                    }

                                    onCountChanged: {
                                        currentIndex = count - 1
                                    }
                                }
                            }
                        }
                    }

                    // Info section
                    Rectangle {
                        width: parent.width
                        height: units.gu(0.1)
                        color: theme.palette.normal.base
                        visible: infoColumn.visible
                    }

                    Column {
                        id: infoColumn
                        width: parent.width
                        spacing: units.gu(1)
                        visible: false

                        Label {
                            text: i18n.tr('System Information')
                            fontSize: "large"
                            font.bold: true
                        }

                        ListItem {
                            height: hostnameLabel.height + units.gu(2)
                            Label {
                                id: hostnameLabel
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: units.gu(1)
                                }
                                text: i18n.tr('Hostname: ') + systemInfo.hostname
                                wrapMode: Text.WordWrap
                            }
                        }

                        ListItem {
                            height: uptimeLabel.height + units.gu(2)
                            Label {
                                id: uptimeLabel
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: units.gu(1)
                                }
                                text: i18n.tr('Uptime: ') + systemInfo.uptime
                                wrapMode: Text.WordWrap
                            }
                        }

                        ListItem {
                            height: cpuLabel.height + units.gu(2)
                            Label {
                                id: cpuLabel
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: units.gu(1)
                                }
                                text: i18n.tr('CPU Usage: ') + systemInfo.cpu + '%'
                                wrapMode: Text.WordWrap
                            }
                        }

                        ListItem {
                            height: ramLabel.height + units.gu(2)
                            Label {
                                id: ramLabel
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: units.gu(1)
                                }
                                text: i18n.tr('RAM Usage: ') + systemInfo.ram
                                wrapMode: Text.WordWrap
                            }
                        }

                        ListItem {
                            height: tempLabel.height + units.gu(2)
                            visible: systemInfo.temperature !== "N/A"
                            Label {
                                id: tempLabel
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: units.gu(1)
                                }
                                text: i18n.tr('Temperature: ') + systemInfo.temperature
                                wrapMode: Text.WordWrap
                            }
                        }

                        Button {
                            width: parent.width
                            text: i18n.tr('Refresh')
                            onClicked: connectToDesktop()
                        }
                    }
                }
            }
        }

        // Setup Instructions Page
        Page {
            id: setupPage
            visible: false
            
            header: PageHeader {
                id: setupHeader
                title: i18n.tr('Setup Guide')
                
                trailingActionBar.actions: [
                    Action {
                        iconName: "close"
                        text: i18n.tr("Close")
                        onTriggered: pageStack.pop()
                    }
                ]
            }

            Flickable {
                anchors {
                    top: setupHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: units.gu(2)
                }
                contentHeight: setupColumn.height
                clip: true

                Column {
                    id: setupColumn
                    width: parent.width
                    spacing: units.gu(2)

                    Label {
                        width: parent.width
                        text: i18n.tr('How It Works')
                        fontSize: "large"
                        font.bold: true
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr('This app connects to a simple web server running on your desktop. ' +
                                     'The server gathers system metrics and provides them via HTTP, which works ' +
                                     'perfectly with Ubuntu Touch\'s security model.')
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(0.1)
                        color: theme.palette.normal.base
                    }

                    Label {
                        width: parent.width
                        text: i18n.tr('Step 1: Download Server Script')
                        fontSize: "large"
                        font.bold: true
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr('Download the server script from the project repository:')
                    }

                    Rectangle {
                        width: parent.width
                        height: downloadLabel.height + units.gu(2)
                        color: theme.palette.normal.foreground
                        radius: units.gu(0.5)

                        Label {
                            id: downloadLabel
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }
                            text: 'github.com/bluebird-documentation/linux-desktop-monitor'
                            wrapMode: Text.Wrap
                            font.family: "Ubuntu Mono"
                            color: theme.palette.normal.foregroundText
                        }
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr('Or the script is included in the app source code as desktop_monitor_server.py')
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(0.1)
                        color: theme.palette.normal.base
                    }

                    Label {
                        width: parent.width
                        text: i18n.tr('Step 2: Start Server on Desktop')
                        fontSize: "large"
                        font.bold: true
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr('On your Linux desktop, run:')
                    }

                    Rectangle {
                        width: parent.width
                        height: commandLabel1.height + units.gu(2)
                        color: theme.palette.normal.foreground
                        radius: units.gu(0.5)

                        Label {
                            id: commandLabel1
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }
                            text: 'python3 desktop_monitor_server.py'
                            wrapMode: Text.Wrap
                            font.family: "Ubuntu Mono"
                            color: theme.palette.normal.foregroundText
                        }
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr('The server will start on port 8080 and display your IP address.')
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(0.1)
                        color: theme.palette.normal.base
                    }

                    Label {
                        width: parent.width
                        text: i18n.tr('Step 3: Connect from App')
                        fontSize: "large"
                        font.bold: true
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr('Enter your desktop\'s IP address in the app and click Connect!')
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(0.1)
                        color: theme.palette.normal.base
                    }

                    Label {
                        width: parent.width
                        text: i18n.tr('Optional: Security Token')
                        fontSize: "large"
                        font.bold: true
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr('For added security, you can start the server with a token:')
                    }

                    Rectangle {
                        width: parent.width
                        height: commandLabel2.height + units.gu(2)
                        color: theme.palette.normal.foreground
                        radius: units.gu(0.5)

                        Label {
                            id: commandLabel2
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }
                            text: 'python3 desktop_monitor_server.py --token mysecrettoken123'
                            wrapMode: Text.Wrap
                            font.family: "Ubuntu Mono"
                            color: theme.palette.normal.foregroundText
                        }
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr('Then enter the same token in the Auth Token field in the app.')
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(0.1)
                        color: theme.palette.normal.base
                    }

                    Label {
                        width: parent.width
                        text: i18n.tr('Advanced Options')
                        fontSize: "large"
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: commandLabel3.height + units.gu(2)
                        color: theme.palette.normal.foreground
                        radius: units.gu(0.5)

                        Label {
                            id: commandLabel3
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }
                            text: '# Change port\npython3 desktop_monitor_server.py --port 9090\n\n# Specific host\npython3 desktop_monitor_server.py --host 192.168.1.100'
                            wrapMode: Text.Wrap
                            font.family: "Ubuntu Mono"
                            color: theme.palette.normal.foregroundText
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: commandLabel4.height + units.gu(2)
                        color: theme.palette.normal.foreground
                        radius: units.gu(0.5)
                        visible: false  // Hide SSH info since we're not using it

                        Label {
                            id: commandLabel4
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }
                            text: 'ssh username@desktop-ip'
                            wrapMode: Text.Wrap
                            font.family: "Ubuntu Mono"
                            color: theme.palette.normal.foregroundText
                        }
                    }

                    Button {
                        width: parent.width
                        text: i18n.tr('Got it! Back to Connection')
                        color: theme.palette.normal.positive
                        onClicked: pageStack.pop()
                    }
                }
            }
        }
    }

    // System info object (will be populated by Python script)
    QtObject {
        id: systemInfo
        property string hostname: ""
        property string uptime: ""
        property string cpu: ""
        property string ram: ""
        property string temperature: ""
    }

    // Log model for debugging
    ListModel {
        id: logModel
    }

    function addLog(message, type) {
        var now = new Date()
        var timestamp = Qt.formatTime(now, "hh:mm:ss")
        logModel.append({
            timestamp: timestamp,
            message: message,
            logType: type || "info"
        })
        console.log("[" + timestamp + "] " + message)
    }

    // SSH Manager is provided as a context property from C++
    // Connect to its signals
    Connections {
        target: sshManager
        ignoreUnknownSignals: true
        
        onConnectionResult: {
            console.log("QML: onConnectionResult called!")
            console.log("QML: result type:", typeof result)
            console.log("QML: result:", JSON.stringify(result))
            
            connectActivity.running = false
            addLog("Connection successful!", "success")
            addLog("Received data: " + JSON.stringify(result), "info")
            
            // Update system info from the result
            systemInfo.hostname = result.hostname || "Unknown"
            systemInfo.uptime = result.uptime || "Unknown"
            systemInfo.cpu = result.cpu || "0"
            systemInfo.ram = result.ram || "Unknown"
            systemInfo.temperature = result.temperature || "N/A"
            
            infoColumn.visible = true
            statusLabel.text = i18n.tr('Connected successfully!')
            statusLabel.color = theme.palette.normal.positive
        }
        
        onErrorOccurred: {
            console.log("QML: onErrorOccurred called!")
            console.log("QML: error:", error)
            
            connectActivity.running = false
            addLog("Error: " + error, "error")
            statusLabel.text = i18n.tr('Error: ') + error
            statusLabel.color = theme.palette.normal.negative
            infoColumn.visible = false
        }
    }

    function connectToDesktop() {
        connectActivity.running = true
        statusLabel.text = i18n.tr('Connecting...')
        statusLabel.color = theme.palette.normal.activity
        infoColumn.visible = false
        
        var port = parseInt(portField.text) || 8080
        var token = passwordField.text || ""
        
        addLog("Connecting to desktop server at " + hostnameField.text + ":" + port, "info")
        if (token) {
            addLog("Using authentication token", "info")
        } else {
            addLog("No authentication token (server must be running without --token)", "info")
        }
        
        // Call the C++ manager (provided as context property)
        try {
            sshManager.connectToHost(
                hostnameField.text,
                "",  // username not used for HTTP
                token,  // password field is now auth token
                port
            )
            addLog("HTTP connection request sent to backend", "info")
        } catch (e) {
            statusLabel.text = i18n.tr('Error: Connection manager not available - ') + e
            statusLabel.color = theme.palette.normal.negative
            connectActivity.running = false
            addLog("Connection error: " + e, "error")
            console.log("Connection error:", e)
        }
    }
}
