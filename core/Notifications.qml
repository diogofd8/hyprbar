pragma Singleton

import QtQuick
import Quickshell
import qs
import "notifications" as Internal

Singleton {
    id: root

    property alias doNotDisturb: persist.doNotDisturb
    readonly property alias model: history
    readonly property alias groups: grouping.model
    readonly property alias popupModel: popups
    readonly property int count: history.count
    property bool centerOpen: false
    signal openRequested()

    PersistentProperties {
        id: persist
        property bool doNotDisturb: false
        // Persist plain data, rather than JS objects tied to the old QML engine.
        property string receivedTimes: "{}"
    }
    ListModel { id: history }
    ListModel { id: popups }
    Internal.NotificationGroups { id: grouping; sourceModel: history }
    Component { id: recordComponent; Internal.NotificationRecord {} }

    function requestOpen(): void {
        root.hideAllPopups()
        root.openRequested()
    }

    function indexOf(model, entry): int {
        for (let i = 0; i < model.count; ++i)
            if (model.get(i).entry === entry)
                return i
        return -1
    }

    function remember(entry): void {
        const times = JSON.parse(persist.receivedTimes)
        times[entry.notificationId] = entry.receivedAt.getTime()
        persist.receivedTimes = JSON.stringify(times)
    }

    function receive(notification): void {
        notification.tracked = true
        const previousTime = JSON.parse(persist.receivedTimes)[notification.id]
        const entry = recordComponent.createObject(root, {
            owner: root, notification: notification,
            receivedAt: new Date(notification.lastGeneration && previousTime
                ? previousTime : Date.now())
        })
        root.remember(entry)
        if (!notification.transient) {
            let index = 0
            while (index < history.count
                && history.get(index).entry.receivedAt > entry.receivedAt)
                ++index
            history.insert(index, {entry: entry})
            while (history.count > Settings.notificationHistoryLimit)
                root.dismiss(history.get(history.count - 1).entry)
        }
        grouping.refresh()
        // Reload restores the history without showing old toasts again.
        if (notification.lastGeneration && notification.transient)
            Qt.callLater(() => root.hidePopup(entry))
        else if (!notification.lastGeneration && entry.alive)
            root.showPopup(entry)
    }

    function updated(entry): void {
        if (!entry.alive)
            return
        entry.receivedAt = new Date()
        root.remember(entry)
        const index = root.indexOf(history, entry)
        if (entry.notification.transient && index >= 0)
            history.remove(index)
        else if (!entry.notification.transient && index < 0)
            history.insert(0, {entry: entry})
        else if (index > 0)
            history.move(index, 0, 1)
        while (history.count > Settings.notificationHistoryLimit)
            root.dismiss(history.get(history.count - 1).entry)
        grouping.refresh()
        if (entry.alive)
            root.showPopup(entry)
    }

    function showPopup(entry): void {
        if (root.doNotDisturb || root.centerOpen
            || Settings.notificationSilentApps.includes(entry.appName)) {
            root.hidePopup(entry)
            return
        }
        const index = root.indexOf(popups, entry)
        if (index < 0)
            popups.insert(0, {entry: entry})
        else if (index > 0)
            popups.move(index, 0, 1)
        entry.popupVisible = true
        entry.restartTimeout()
        while (popups.count > Settings.notificationPopupLimit)
            root.hidePopup(popups.get(popups.count - 1).entry)
    }

    function hidePopup(entry): void {
        if (!entry || !entry.alive)
            return
        entry.popupVisible = false
        entry.popupHovered = false
        const index = root.indexOf(popups, entry)
        if (index >= 0)
            popups.remove(index)
        // Ordinary notifications stay in history after their toast disappears.
        if (entry.alive && entry.notification.transient)
            entry.notification.expire()
    }

    function dismiss(entry): void {
        if (entry && entry.alive)
            entry.notification.dismiss()
    }

    function hideAllPopups(): void {
        while (popups.count > 0)
            root.hidePopup(popups.get(0).entry)
    }

    function clearAll(): void {
        while (history.count > 0)
            root.dismiss(history.get(0).entry)
    }

    function dismissGroup(group): void {
        // Closing a notification changes the group's model synchronously.
        const entries = []
        for (let i = 0; i < group.model.count; ++i)
            entries.push(group.model.get(i).entry)
        for (const entry of entries)
            root.dismiss(entry)
    }

    function forget(entry): void {
        entry.alive = false
        entry.popupVisible = false
        for (const model of [history, popups]) {
            const index = root.indexOf(model, entry)
            if (index >= 0)
                model.remove(index)
        }
        grouping.refresh()
        const times = JSON.parse(persist.receivedTimes)
        delete times[entry.notificationId]
        persist.receivedTimes = JSON.stringify(times)
        entry.destroy()
    }

    onDoNotDisturbChanged: {
        if (root.doNotDisturb)
            root.hideAllPopups()
    }
    onCenterOpenChanged: { if (root.centerOpen) root.hideAllPopups() }
}
