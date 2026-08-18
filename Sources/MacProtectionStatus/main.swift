import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let settingsWindowController = SettingsWindowController()
    private let menu = NSMenu()
    private var monitorTimer: Timer?
    private var countdownTimer: Timer?
    private var lastCheckedAt: Date?
    private var nextCheckAt: Date?
    private var isMenuOpen = false
    private let checkInterval: TimeInterval = 30
    private var previousFailingTitles: Set<String>?

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        menu.delegate = self
        statusItem.menu = menu

        // UNUserNotificationCenter requires a proper app bundle identifier; accessing it
        // when running as a raw binary (e.g. `swift run`) throws an uncaught NSException.
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .appLanguageChanged,
            object: nil
        )

        refreshStatus()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.isMenuOpen else { return }
            self.rebuildMenu(statuses: SecurityStatus.allStatuses())
        }
    }

    @objc private func languageDidChange() {
        let statuses = SecurityStatus.allStatuses()
        updateIcon(statuses: statuses)
        rebuildMenu(statuses: statuses)
    }

    // Recomputes security status in the background and updates the menu bar icon.
    // Runs continuously on a timer, independent of whether the menu is open.
    private func refreshStatus() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let statuses = SecurityStatus.allStatuses()
            DispatchQueue.main.async {
                guard let self else { return }
                self.lastCheckedAt = Date()
                self.nextCheckAt = Date().addingTimeInterval(self.checkInterval)
                self.notifyIfNewlyFailing(statuses: statuses)
                self.updateIcon(statuses: statuses)
                if !self.isMenuOpen {
                    self.rebuildMenu(statuses: statuses)
                }
            }
        }
    }

    // Fires a macOS notification the moment a previously-OK item turns into a warning,
    // so the user finds out without having to open the menu.
    private func notifyIfNewlyFailing(statuses: [StatusItem]) {
        let failingTitles = Set(statuses.filter { !$0.ok }.map(\.title))
        defer { previousFailingTitles = failingTitles }

        guard Bundle.main.bundleIdentifier != nil else { return }
        guard let previousFailingTitles else { return }
        let newlyFailing = failingTitles.subtracting(previousFailingTitles)
        for title in newlyFailing {
            let content = UNMutableNotificationContent()
            content.title = L10n.string(ko: "보안 항목이 꺼졌습니다", en: "A security item was turned off")
            content.body = L10n.string(ko: "\(title) 항목을 확인해 주세요.", en: "Please check \(title).")
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func updateIcon(statuses: [StatusItem]) {
        let allOk = statuses.allSatisfy { $0.ok }
        if let button = statusItem.button {
            let symbolName = allOk ? "checkmark.shield.fill" : "exclamationmark.shield.fill"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: L10n.string(ko: "보안 상태", en: "Security Status"))
        }
    }

    private func rebuildMenu(statuses: [StatusItem]) {
        menu.removeAllItems()

        let summaryHeader = NSMenuItem()
        summaryHeader.view = SummaryBadgeView(statuses: statuses)
        menu.addItem(summaryHeader)
        menu.addItem(NSMenuItem.separator())

        let monitoringHeader = NSMenuItem()
        monitoringHeader.view = MonitoringHeaderView()
        menu.addItem(monitoringHeader)
        menu.addItem(NSMenuItem.separator())

        let gridHeader = NSMenuItem()
        gridHeader.view = SecurityGridView(statuses: statuses)
        menu.addItem(gridHeader)

        for item in statuses {
            guard let resolveURL = item.resolveURL else { continue }
            let resolveItem = NSMenuItem(
                title: "\(item.title) → \(item.resolveTitle ?? L10n.string(ko: "지금 열기", en: "Open Now"))",
                action: #selector(openResolveURL(_:)),
                keyEquivalent: ""
            )
            resolveItem.target = self
            resolveItem.representedObject = resolveURL
            menu.addItem(resolveItem)
        }

        menu.addItem(NSMenuItem.separator())

        if let lastCheckedAt {
            let lastCheckedItem = NSMenuItem(
                title: L10n.string(ko: "마지막 확인", en: "Last checked") + ": \(dateFormatter.string(from: lastCheckedAt))",
                action: nil,
                keyEquivalent: ""
            )
            lastCheckedItem.isEnabled = false
            menu.addItem(lastCheckedItem)
        }

        if let nextCheckAt {
            let remaining = max(0, Int(nextCheckAt.timeIntervalSinceNow.rounded()))
            let nextCheckItem = NSMenuItem(
                title: L10n.string(ko: "다음 확인까지", en: "Next check in") + ": \(remaining)s",
                action: nil,
                keyEquivalent: ""
            )
            nextCheckItem.isEnabled = false
            menu.addItem(nextCheckItem)
        }

        let descriptionItem = NSMenuItem()
        descriptionItem.view = DescriptionView(text: L10n.string(
            ko: "macOS는 XProtect, Gatekeeper, SIP 등 내장 보호 기능을 자동으로 제공합니다.",
            en: "macOS automatically provides built-in protections like XProtect, Gatekeeper, and SIP."
        ))
        menu.addItem(descriptionItem)
        menu.addItem(NSMenuItem.separator())

        let softwareUpdateItem = NSMenuItem(
            title: L10n.string(ko: "소프트웨어 업데이트 확인", en: "Check Software Update"),
            action: #selector(openSoftwareUpdate),
            keyEquivalent: ""
        )
        softwareUpdateItem.target = self
        menu.addItem(softwareUpdateItem)

        let settingsItem = NSMenuItem(
            title: L10n.string(ko: "설정...", en: "Settings..."),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(
            title: L10n.string(ko: "종료", en: "Quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
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

    @objc private func openSoftwareUpdate() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.softwareupdate") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openResolveURL(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }
}

/// Custom menu row: a single-line badge summarizing overall protection status,
/// shown above the individual item list ("Safe" vs "Needs attention").
final class SummaryBadgeView: NSView {
    init(statuses: [StatusItem]) {
        super.init(frame: NSRect(x: 0, y: 0, width: MenuLayout.contentWidth, height: 32))

        let failingCount = statuses.filter { !$0.ok }.count
        let allOk = failingCount == 0

        let icon = NSImageView()
        icon.image = NSImage(
            systemSymbolName: allOk ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
            accessibilityDescription: nil
        )
        icon.contentTintColor = allOk ? .systemGreen : .systemOrange
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: allOk
            ? L10n.string(ko: "안전함", en: "Safe")
            : L10n.string(ko: "주의 필요 · \(failingCount)개 항목", en: "Needs attention · \(failingCount) item(s)"))
        label.font = NSFont.boldSystemFont(ofSize: 14)
        label.textColor = allOk ? .systemGreen : .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(icon)
        addSubview(label)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Custom menu row: a spinning indicator + "실시간 감시 중입니다" label.
/// The spinner runs continuously while the app is alive, reflecting the
/// background monitoring timer in AppDelegate that keeps re-checking status.
final class MonitoringHeaderView: NSView {
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: MenuLayout.contentWidth, height: 28))

        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimation(nil)

        let label = NSTextField(labelWithString: L10n.string(ko: "실시간 감시 중입니다", en: "Monitoring in real time"))
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

/// Custom menu row: a wrapped, multi-line label. Plain NSMenuItem titles never
/// wrap, so a long single-line description can force the whole menu (and the
/// card grid inside it) wider than intended.
final class DescriptionView: NSView {
    init(text: String) {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.preferredMaxLayoutWidth = MenuLayout.contentWidth - 28
        let height = label.fittingSize.height
        super.init(frame: NSRect(x: 0, y: 0, width: MenuLayout.contentWidth, height: height))

        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
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
