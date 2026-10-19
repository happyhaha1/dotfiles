import "CompatUi" as ThemeUi
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Andy Stewart
//
// Local change against upstream (see README.md): the bar shows the Chinese
// weekday and time instead of the calendar icon, so the clock and the calendar
// are one widget and one click apart.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
    id: root
    moduleName: "local.days"
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    readonly property bool opened: panel.opened
    readonly property bool popoutSwitchClosing: panel.popoutSwitchClosing
    readonly property bool preservePopupContentAppearance: true
    property Item popupAnchor: button

    // ---- Local change: label text.
    property date displayDate: clock.date
    readonly property var labelLocale: Qt.locale(setting("locale", "zh_CN"))
    // A vertical bar has no room for a weekday word, so it gets time only.
    readonly property string label: labelLocale.toString(displayDate, vertical ? "HH:mm" : setting("format", "dddd HH:mm"))

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: root.displayDate = date
    }

    function open(anchor) { root.popupAnchor = anchor || button; panel.open() }
    function close() { panel.close() }
    function toggle(anchor) { root.opened ? root.close() : root.open(anchor) }
    function closeForPopoutSwitch() { panel.closeForPopoutSwitch() }
    function persist(values) {
        var entry = {id: root.moduleName}
        for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
        for (var field in values) entry[field] = values[field]
        var changed = false
        for (var name in values) {
            if (JSON.stringify(root.settings[name]) !== JSON.stringify(values[name])) changed = true
        }
        // updateEntryInline returns false for a no-op, not just an error.
        if (!changed) { panel.settingsError = ""; return }
        if (!root.bar || !root.bar.shell || typeof root.bar.shell.updateEntryInline !== "function") {
            panel.settingsError = "城市设置保存接口不可用，请重新加载插件"
            return
        }
        if (!root.bar.shell.updateEntryInline(root.moduleName, entry)) {
            panel.settingsError = "城市设置保存失败，请重新打开插件后重试"
            return
        }
        // Let the host update settings on every monitor through its config
        // change handler; avoid a separate local-only settings assignment.
        panel.settingsError = ""
    }

    // ---- Local change: text label instead of upstream's ThemeUi.BarIconButton
    // with the CalendarIcon glyph.
    ThemeUi.WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.label
        active: root.opened
        tooltipText: "日历与天气"
        horizontalMargin: 8.75
        verticalPadding: 8.75
        onPressed: function(b) {
            if (b === Qt.MiddleButton) panel.refresh()
            else if (b === Qt.LeftButton) root.toggle()
        }
    }
    DaysPanel {
        id: panel
        bar: root.bar
        anchorItem: root.popupAnchor
        hostWidget: root
        city: root.setting("city", null)
        locationMode: root.setting("locationMode", "auto")
        onCitySelected: function(city) { root.persist({locationMode: "manual", city: city}) }
        onAutomaticRequested: root.persist({locationMode: "auto", city: null})
    }
    IpcHandler {
        target: "local.days"
        function open(): void { root.open() }
        function show(): void { root.open() }
        function close(): void { root.close() }
        function hide(): void { root.close() }
        function toggle(): void { root.toggle() }
        function refresh(): void { panel.refresh() }
    }
}
