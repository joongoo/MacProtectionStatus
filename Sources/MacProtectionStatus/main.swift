import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let settingsWindowController = SettingsWindowController()
    private let menu = NSMenu()
    private var monitorTimer: Timer?
    private var lastCheckedAt: Date?
    private var isMenuOpen = false
    private let checkInterval: TimeInterval = 30

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        menu.delegate = self
        statusItem.menu = menu

        refreshStatus()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    // Recomputes security status in the background and updates the menu bar icon.
    // Runs continuously on a timer, independent of whether the menu is open.
    private func refreshStatus() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let statuses = SecurityStatus.allStatuses()
            DispatchQueue.main.async {
                guard let self else { return }
                self.lastCheckedAt = Date()
                self.updateIcon(statuses: statuses)
                if !self.isMenuOpen {
                    self.rebuildMenu(statuses: statuses)
                }
            }
        }
    }

    private func updateIcon(statuses: [StatusItem]) {
        let allOk = statuses.allSatisfy { $0.ok }
        if let button = statusItem.button {
            let symbolName = allOk ? "checkmark.shield.fill" : "exclamationmark.shield.fill"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "보안 상태")
        }
    }

    private func rebuildMenu(statuses: [StatusItem]) {
        menu.removeAllItems()

        let monitoringHeader = NSMenuItem()
        monitoringHeader.view = MonitoringHeaderView()
        menu.addItem(monitoringHeader)
        menu.addItem(NSMenuItem.separator())

        for item in statuses {
            let mark = item.ok ? "✅" : "⚠️"
            let menuItem = NSMenuItem(title: "\(mark) \(item.title)", action: nil, keyEquivalent: "")
            menu.addItem(menuItem)
            let detailItem = NSMenuItem(title: "    \(item.detail)", action: nil, keyEquivalent: "")
            detailItem.isEnabled = false
            menu.addItem(detailItem)
        }

        menu.addItem(NSMenuItem.separator())

        if let lastCheckedAt {
            let lastCheckedItem = NSMenuItem(
                title: "마지막 확인: \(dateFormatter.string(from: lastCheckedAt))",
                action: nil,
                keyEquivalent: ""
            )
            lastCheckedItem.isEnabled = false
            menu.addItem(lastCheckedItem)
        }

        menu.addItem(NSMenuItem(
            title: "macOS는 XProtect, Gatekeeper, SIP 등 내장 보호 기능을 자동으로 제공합니다.",
            action: nil,
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "설정...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true
        rebuildMenu(statuses: SecurityStatus.allStatuses())
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
    }

    @objc private func openSettings() {
        settingsWindowController.show()
    }
}

/// Custom menu row: a spinning indicator + "실시간 감시 중입니다" label.
/// The spinner runs continuously while the app is alive, reflecting the
/// background monitoring timer in AppDelegate that keeps re-checking status.
final class MonitoringHeaderView: NSView {
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 28))

        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimation(nil)

        let label = NSTextField(labelWithString: "실시간 감시 중입니다")
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(spinner)
        addSubview(label)

        NSLayoutConstraint.activate([
            spinner.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.widthAnchor.constraint(equalToConstant: 16),
            spinner.heightAnchor.constraint(equalToConstant: 16),

            label.leadingAnchor.constraint(equalTo: spinner.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
