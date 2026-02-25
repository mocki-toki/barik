import AppKit

final class MenuBarContextMenu: NSMenu, NSMenuDelegate {
    private static let widgetEntries: [(id: String, name: String)] = [
        ("default.spaces", "Spaces"),
        ("default.network", "Network"),
        ("default.battery", "Battery"),
        ("default.time", "Time & Calendar"),
        ("default.nowplaying", "Now Playing"),
        ("default.weather", "Weather"),
        ("default.claude-usage", "Claude Usage"),
        ("default.pomodoro", "Pomodoro"),
        ("default.countdown", "Countdown"),
    ]

    override init(title: String = "") {
        super.init(title: title)
        self.delegate = self
        self.autoenablesItems = false
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.delegate = self
        self.autoenablesItems = false
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let displayedIds = ConfigManager.shared.config.rootToml.widgets.displayed.map(\.id)

        for entry in Self.widgetEntries {
            let item = NSMenuItem(
                title: entry.name,
                action: #selector(toggleWidget(_:)),
                keyEquivalent: "")
            item.target = self
            item.representedObject = entry.id
            item.state = displayedIds.contains(entry.id) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let editItem = NSMenuItem(
            title: "Edit Config...",
            action: #selector(openConfig),
            keyEquivalent: "")
        editItem.target = self
        menu.addItem(editItem)

        let quitItem = NSMenuItem(
            title: "Quit Barik",
            action: #selector(quitApp),
            keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func toggleWidget(_ sender: NSMenuItem) {
        guard let widgetId = sender.representedObject as? String else { return }
        ConfigManager.shared.toggleWidget(widgetId)
    }

    @objc private func openConfig() {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let path1 = "\(homePath)/.barik-config.toml"
        let path2 = "\(homePath)/.config/barik/config.toml"

        let path: String
        if FileManager.default.fileExists(atPath: path1) {
            path = path1
        } else if FileManager.default.fileExists(atPath: path2) {
            path = path2
        } else {
            return
        }

        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
