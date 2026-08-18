import AppKit
import ServiceManagement

final class SettingsWindowController: NSWindowController {

    private let launchToggle = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let languagePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let languageLabel = NSTextField(labelWithString: "")

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 190),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        setupUI()
        applyLocalizedText()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = NSFont.systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        launchToggle.translatesAutoresizingMaskIntoConstraints = false
        launchToggle.target = self
        launchToggle.action = #selector(toggleLaunchAtLogin)
        launchToggle.state = LoginItemManager.isEnabled ? .on : .off

        languageLabel.font = NSFont.systemFont(ofSize: 13)
        languageLabel.translatesAutoresizingMaskIntoConstraints = false

        languagePopup.translatesAutoresizingMaskIntoConstraints = false
        languagePopup.target = self
        languagePopup.action = #selector(languageSelectionChanged)
        for language in AppLanguage.allCases {
            languagePopup.addItem(withTitle: language.displayName)
        }
        if let index = AppLanguage.allCases.firstIndex(of: L10n.current) {
            languagePopup.selectItem(at: index)
        }

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(launchToggle)
        contentView.addSubview(languageLabel)
        contentView.addSubview(languagePopup)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            launchToggle.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            launchToggle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            languageLabel.topAnchor.constraint(equalTo: launchToggle.bottomAnchor, constant: 18),
            languageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            languagePopup.centerYAnchor.constraint(equalTo: languageLabel.centerYAnchor),
            languagePopup.leadingAnchor.constraint(equalTo: languageLabel.trailingAnchor, constant: 10),
            languagePopup.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
        ])
    }

    private func applyLocalizedText() {
        window?.title = L10n.string(ko: "설정", en: "Settings")
        titleLabel.stringValue = L10n.string(ko: "Mac 보안 상태", en: "Mac Security Status")
        subtitleLabel.stringValue = L10n.string(
            ko: "메뉴바에서 XProtect, Gatekeeper, FileVault, SIP 상태를 확인합니다.",
            en: "Check XProtect, Gatekeeper, FileVault, and SIP status from the menu bar."
        )
        launchToggle.title = L10n.string(ko: "로그인 시 자동으로 실행", en: "Launch at login")
        languageLabel.stringValue = L10n.string(ko: "언어", en: "Language")
    }

    @objc private func toggleLaunchAtLogin() {
        let shouldEnable = launchToggle.state == .on
        do {
            try LoginItemManager.setEnabled(shouldEnable)
        } catch {
            launchToggle.state = LoginItemManager.isEnabled ? .on : .off
            let alert = NSAlert()
            alert.messageText = L10n.string(ko: "설정을 변경할 수 없습니다", en: "Unable to change setting")
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    @objc private func languageSelectionChanged() {
        let language = AppLanguage.allCases[languagePopup.indexOfSelectedItem]
        L10n.current = language
        applyLocalizedText()
    }

    func show() {
        launchToggle.state = LoginItemManager.isEnabled ? .on : .off
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

enum LoginItemManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        }
    }
}
