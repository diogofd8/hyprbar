import Quickshell.Services.Notifications
import qs.core

// Instantiated by shell.qml, never by the popup or its standalone preview.
NotificationServer {
    keepOnReload: true
    persistenceSupported: true
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    onNotification: notification => Notifications.receive(notification)
}
