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
    
    // Use app-specific writable directory
    property string downloadsPath: "/home/phablet/.local/share/" + applicationName

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

                    // Bluebird Documentation link
                    Label {
                        width: parent.width
                        textFormat: Text.RichText
                        text: '<b>Powered by <a href="https://www.bluebird-documentation.com">Bluebird Documentation</a></b>'
                        fontSize: "small"
                        color: theme.palette.normal.activity
                        horizontalAlignment: Text.AlignHCenter
                        onLinkActivated: {
                            Qt.openUrlExternally(link)
                        }
                    }
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

                        Button {
                            width: parent.width
                            text: i18n.tr('📁 Browse Desktop Files')
                            color: theme.palette.normal.base
                            enabled: systemInfo.hostname !== ""
                            onClicked: {
                                fileBrowser.hostAddress = hostnameField.text
                                fileBrowser.portNumber = parseInt(portField.text) || 8080
                                fileBrowser.currentPath = "/"
                                fileBrowser.loadDirectory("/")
                                pageStack.push(fileBrowserPage)
                            }
                        }

                        Button {
                            width: parent.width
                            text: i18n.tr('⚠️ Shutdown Desktop')
                            color: theme.palette.normal.negative
                            enabled: systemInfo.hostname !== ""
                            onClicked: {
                                PopupUtils.open(shutdownConfirmDialog)
                            }
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
                        text: i18n.tr('Download the server script from our documentation:')
                    }

                    Rectangle {
                        width: parent.width
                        height: downloadLabel.height + units.gu(4)
                        color: theme.palette.normal.foreground
                        radius: units.gu(0.5)

                        Label {
                            id: downloadLabel
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }
                            text: 'https://bluebird-documentation.com/documentation/page/Linux%20Desktop%20Monitor/NGzFPNeV9GY1g6q2PFX7SfQmRqw1/'
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

                    Item {
                        width: parent.width
                        height: units.gu(5)
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

        // File Browser Page
        Page {
            id: fileBrowserPage
            visible: false
            
            header: PageHeader {
                id: fileBrowserHeader
                title: i18n.tr('File Browser')
                
                trailingActionBar.actions: [
                    Action {
                        iconName: "add"
                        text: i18n.tr("Upload File")
                        onTriggered: PopupUtils.open(uploadDialog)
                    },
                    Action {
                        iconName: "close"
                        text: i18n.tr("Close")
                        onTriggered: pageStack.pop()
                    }
                ]
            }

            QtObject {
                id: fileBrowser
                property string hostAddress: ""
                property int portNumber: 8080
                property string currentPath: "/"
                property var fileItems: []
                property string parentPath: null
                property bool loading: false

                function loadDirectory(path) {
                    loading = true
                    fileItems = []
                    sshManager.listFiles(hostAddress, portNumber, path)
                }
            }

            Flickable {
                anchors {
                    top: fileBrowserHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                contentHeight: fileBrowserColumn.height
                clip: true

                Column {
                    id: fileBrowserColumn
                    width: parent.width

                    // Current path indicator
                    Rectangle {
                        width: parent.width
                        height: pathLabel.height + units.gu(2)
                        color: theme.palette.normal.background

                        Label {
                            id: pathLabel
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: units.gu(2)
                            }
                            text: i18n.tr("Path: ") + fileBrowser.currentPath
                            wrapMode: Text.WordWrap
                            fontSize: "small"
                        }
                    }

                    // Loading indicator
                    ActivityIndicator {
                        anchors.horizontalCenter: parent.horizontalCenter
                        running: fileBrowser.loading
                        visible: fileBrowser.loading
                    }

                    // Parent directory button
                    ListItem {
                        visible: fileBrowser.parentPath !== null && !fileBrowser.loading
                        height: units.gu(6)
                        
                        leadingActions: ListItemActions {
                            actions: [
                                Action {
                                    iconName: "back"
                                }
                            ]
                        }

                        Label {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: units.gu(2)
                                rightMargin: units.gu(2)
                            }
                            text: i18n.tr(".. (Parent Directory)")
                            color: theme.palette.normal.activity
                        }

                        onClicked: {
                            if (fileBrowser.parentPath) {
                                fileBrowser.currentPath = fileBrowser.parentPath
                                fileBrowser.loadDirectory(fileBrowser.parentPath)
                            }
                        }
                    }

                    // File list
                    Repeater {
                        model: fileBrowser.fileItems
                        delegate: ListItem {
                            height: units.gu(7)
                            
                            leadingActions: ListItemActions {
                                actions: [
                                    Action {
                                        iconName: modelData.is_dir ? "folder" : "document"
                                    }
                                ]
                            }

                            Column {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: units.gu(2)
                                    rightMargin: units.gu(2)
                                }
                                spacing: units.gu(0.5)

                                Label {
                                    text: modelData.name
                                    font.bold: modelData.is_dir
                                }

                                Label {
                                    visible: !modelData.is_dir
                                    text: formatFileSize(modelData.size)
                                    fontSize: "small"
                                    color: theme.palette.normal.backgroundSecondaryText
                                }
                            }

                            onClicked: {
                                if (modelData.is_dir) {
                                    // Navigate into directory
                                    var newPath = fileBrowser.currentPath === "/" 
                                        ? "/" + modelData.name 
                                        : fileBrowser.currentPath + "/" + modelData.name
                                    fileBrowser.currentPath = newPath
                                    fileBrowser.loadDirectory(newPath)
                                } else {
                                    // File clicked - show download option
                                    var filePath = fileBrowser.currentPath === "/" 
                                        ? "/" + modelData.name 
                                        : fileBrowser.currentPath + "/" + modelData.name
                                    PopupUtils.open(downloadDialog, null, {
                                        fileName: modelData.name,
                                        filePath: filePath
                                    })
                                }
                            }
                        }
                    }

                    // Empty state
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: fileBrowser.fileItems.length === 0 && !fileBrowser.loading
                        text: i18n.tr("No files in this directory")
                        color: theme.palette.normal.backgroundSecondaryText
                    }
                }
            }
        }

        // Download confirmation dialog
        Component {
            id: downloadDialog
            Dialog {
                id: dlg
                property string fileName: ""
                property string filePath: ""
                
                title: i18n.tr("Download File")
                
                Column {
                    width: parent.width
                    spacing: units.gu(2)
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("File: ") + dlg.fileName
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("Save to:")
                        fontSize: "small"
                    }
                    
                    TextField {
                        id: savePathField
                        width: parent.width
                        text: root.downloadsPath + "/" + dlg.fileName
                        placeholderText: i18n.tr("Enter destination path")
                    }
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("Files save to app folder by default.\n\nAccess downloaded files:\n1. Open File Manager\n2. Navigate to: .local/share/linux-desktop-monitor.../\n\nOr copy path from logs after download.")
                        fontSize: "x-small"
                        color: theme.palette.normal.backgroundSecondaryText
                        wrapMode: Text.WordWrap
                    }
                }
                
                Button {
                    text: i18n.tr("Cancel")
                    onClicked: PopupUtils.close(dlg)
                }
                
                Button {
                    text: i18n.tr("Download")
                    color: theme.palette.normal.positive
                    onClicked: {
                        var savePath = savePathField.text.trim()
                        if (savePath === "") {
                            savePath = "/home/phablet/Documents/" + dlg.fileName
                        }
                        PopupUtils.close(dlg)
                        addLog("Downloading " + dlg.fileName + " to " + savePath, "info")
                        sshManager.downloadFile(fileBrowser.hostAddress, fileBrowser.portNumber, dlg.filePath, savePath)
                    }
                }
            }
        }

        // Upload dialog
        Component {
            id: uploadDialog
            Dialog {
                id: uploadDlg
                
                title: i18n.tr("Upload File to Desktop")
                
                Column {
                    width: parent.width
                    spacing: units.gu(2)
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("Destination on Desktop:")
                        fontSize: "medium"
                        font.bold: true
                    }
                    
                    // Label {
                    //     width: parent.width
                    //     text: fileBrowser.currentPath
                    //     wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    //     fontSize: "small"
                    //     color: theme.palette.normal.backgroundSecondaryText
                    // }
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("ℹ️ The file will be uploaded to the folder shown above on your desktop where the server is running.")
                        fontSize: "x-small"
                        color: theme.palette.normal.backgroundTertiaryText
                        wrapMode: Text.WordWrap
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: units.gu(0.1)
                        color: theme.palette.normal.base
                    }
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("File path on your phone:")
                        fontSize: "small"
                    }
                    
                    TextField {
                        id: uploadPathField
                        width: parent.width
                        placeholderText: "e.g., myfile.pdf or full path"
                        text: ""
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onTextChanged: {
                            console.log("=== TextField onTextChanged ===")
                            console.log("text property:", text)
                            console.log("displayText:", displayText)
                            console.log("text.length:", text.length)
                            for (var i = 0; i < text.length; i++) {
                                console.log("  char[" + i + "]:", text.charAt(i), "code:", text.charCodeAt(i))
                            }
                        }
                    }
                    
                    Label {
                        width: parent.width
                        text: "App folder: " + root.downloadsPath + "/\n\nJust enter the filename (e.g., 'document.pdf') if it's in the app folder.\n\nOr enter a full path like:\n" + root.downloadsPath + "/myfile.pdf"
                        fontSize: "x-small"
                        color: theme.palette.normal.backgroundSecondaryText
                        wrapMode: Text.WordWrap
                    }
                    
                    Label {
                        width: parent.width
                        text: "⚠️ Note: Due to app permissions, you may only be able to upload files from the app's folder. To upload other files, first save/copy them to the app folder."
                        fontSize: "x-small"
                        color: theme.palette.normal.negative
                        wrapMode: Text.WordWrap
                    }
                }
                
                Button {
                    text: i18n.tr("Cancel")
                    onClicked: PopupUtils.close(uploadDlg)
                }
                
                Button {
                    text: i18n.tr("Upload")
                    color: theme.palette.normal.positive
                    onClicked: {
                        console.log("=== Upload Button Clicked ===")
                        console.log("uploadPathField.text:", uploadPathField.text)
                        console.log("uploadPathField.displayText:", uploadPathField.displayText)
                        console.log("uploadPathField.text type:", typeof uploadPathField.text)
                        
                        var localPath = uploadPathField.text.trim()
                        console.log("After trim:", localPath)
                        console.log("After trim length:", localPath.length)
                        
                        // Print each character
                        for (var i = 0; i < localPath.length; i++) {
                            console.log("  localPath[" + i + "]:", localPath.charAt(i), "code:", localPath.charCodeAt(i))
                        }
                        
                        if (localPath === "") {
                            addLog("Please enter a file path", "error")
                            return
                        }
                        
                        // If it's just a filename (no path separator), assume it's in the app folder
                        if (localPath.indexOf("/") === -1) {
                            console.log("No slash found, prepending app path")
                            localPath = root.downloadsPath + "/" + localPath
                        }
                        // If it starts with ~, expand it
                        else if (localPath.indexOf("~/") === 0) {
                            console.log("Expanding ~ path")
                            localPath = localPath.replace("~/", "/home/phablet/")
                        }
                        
                        console.log("=== Final Path ===")
                        console.log("Final upload path:", localPath)
                        console.log("Final path length:", localPath.length)
                        for (var j = 0; j < localPath.length; j++) {
                            console.log("  finalPath[" + j + "]:", localPath.charAt(j), "code:", localPath.charCodeAt(j))
                        }
                        
                        addLog("Uploading from: " + localPath, "info")
                        
                        PopupUtils.close(uploadDlg)
                        sshManager.uploadFile(fileBrowser.hostAddress, fileBrowser.portNumber, localPath, fileBrowser.currentPath)
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
        
        onShutdownResult: {
            console.log("QML: onShutdownResult called!")
            console.log("QML: success:", success, "message:", message)
            
            if (success) {
                addLog("Shutdown command sent successfully: " + message, "success")
                statusLabel.text = i18n.tr('Desktop shutdown initiated')
                statusLabel.color = theme.palette.normal.activity
            } else {
                addLog("Shutdown failed: " + message, "error")
                statusLabel.text = i18n.tr('Shutdown failed: ') + message
                statusLabel.color = theme.palette.normal.negative
            }
        }
        
        onFileListResult: {
            console.log("QML: onFileListResult called!")
            fileBrowser.loading = false
            fileBrowser.fileItems = result.items || []
            fileBrowser.parentPath = result.parent
            addLog("Loaded " + fileBrowser.fileItems.length + " items from " + result.path, "info")
        }
        
        onDownloadComplete: {
            console.log("QML: File downloaded:", filename, "to", savePath)
            addLog("Download complete: " + filename, "success")
            statusLabel.text = i18n.tr('Downloaded: ') + filename
            statusLabel.color = theme.palette.normal.positive
        }
        
        onDownloadProgress: {
            console.log("QML: Download progress:", filename, progress + "%")
            if (progress % 25 === 0) {  // Log every 25%
                addLog("Downloading " + filename + ": " + progress + "%", "info")
            }
        }
        
        onUploadComplete: {
            console.log("QML: File uploaded:", filename)
            addLog("Upload complete: " + filename, "success")
            statusLabel.text = i18n.tr('Uploaded: ') + filename
            statusLabel.color = theme.palette.normal.positive
        }
        
        onUploadProgress: {
            console.log("QML: Upload progress:", filename, progress + "%")
            if (progress % 25 === 0) {  // Log every 25%
                addLog("Uploading " + filename + ": " + progress + "%", "info")
            }
        }
        
        onFileError: {
            console.log("QML: File error:", error)
            addLog("File operation error: " + error, "error")
            fileBrowser.loading = false
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

    function formatFileSize(bytes) {
        if (bytes === 0) return "0 B"
        var k = 1024
        var sizes = ["B", "KB", "MB", "GB", "TB"]
        var i = Math.floor(Math.log(bytes) / Math.log(k))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
    }

    function shutdownDesktop() {
        addLog("Sending shutdown command to " + hostnameField.text, "info")
        var port = parseInt(portField.text) || 8080
        
        try {
            sshManager.shutdownDesktop(hostnameField.text, port)
        } catch (e) {
            addLog("Shutdown error: " + e, "error")
            console.log("Shutdown error:", e)
        }
    }

    // Shutdown confirmation dialog
    Component {
        id: shutdownConfirmDialog
        Dialog {
            id: confirmDialog
            title: i18n.tr("Shutdown Desktop?")
            text: i18n.tr("This will shutdown your desktop computer ") + systemInfo.hostname + 
                  i18n.tr(". Are you sure?")
            
            Button {
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(confirmDialog)
            }
            
            Button {
                text: i18n.tr("Shutdown")
                color: theme.palette.normal.negative
                onClicked: {
                    PopupUtils.close(confirmDialog)
                    shutdownDesktop()
                }
            }
        }
    }
}
