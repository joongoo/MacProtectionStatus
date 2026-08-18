import Foundation

struct StatusItem {
    let title: String
    let shortTitle: String
    let symbolName: String
    let detail: String
    let ok: Bool
    let resolveURL: URL?
    let resolveTitle: String?

    init(
        title: String,
        shortTitle: String? = nil,
        symbolName: String = "checkmark.shield",
        detail: String,
        ok: Bool,
        resolveURL: URL? = nil,
        resolveTitle: String? = nil
    ) {
        self.title = title
        self.shortTitle = shortTitle ?? title
        self.symbolName = symbolName
        self.detail = detail
        self.ok = ok
        self.resolveURL = resolveURL
        self.resolveTitle = resolveTitle
    }
}

enum SecurityStatus {

    private static func run(_ path: String, _ args: [String]) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static func xprotectStatus() -> StatusItem {
        let plistPath = "/Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist"
        guard let dict = NSDictionary(contentsOfFile: plistPath),
              let version = dict["CFBundleShortVersionString"] as? String else {
            return StatusItem(
                title: "XProtect",
                shortTitle: L10n.string(ko: "악성코드 방지", en: "Malware Protection"),
                symbolName: "ladybug",
                detail: L10n.string(ko: "상태를 확인할 수 없음", en: "Unable to check status"),
                ok: false
            )
        }

        let staleThresholdDays = 180
        var daysSinceUpdate: Int?
        if let modDate = (try? FileManager.default.attributesOfItem(atPath: plistPath))?[.modificationDate] as? Date {
            daysSinceUpdate = Calendar.current.dateComponents([.day], from: modDate, to: Date()).day
        }
        let isStale = (daysSinceUpdate ?? 0) > staleThresholdDays

        let detail: String
        if let daysSinceUpdate, isStale {
            detail = L10n.string(
                ko: "정의 버전 \(version) · \(daysSinceUpdate)일간 갱신 안 됨 (OS가 오래되었을 수 있음)",
                en: "Definitions v\(version) · not updated in \(daysSinceUpdate) days (OS may be outdated)"
            )
        } else {
            detail = L10n.string(ko: "활성 · 정의 버전 \(version)", en: "Active · Definitions v\(version)")
        }

        return StatusItem(
            title: L10n.string(ko: "XProtect (악성코드 검사)", en: "XProtect (Malware Scan)"),
            shortTitle: L10n.string(ko: "악성코드 방지", en: "Malware Protection"),
            symbolName: "ladybug",
            detail: detail,
            ok: !isStale
        )
    }

    private static let isoDateParser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // Reports macOS version and when the system last checked for software updates,
    // using only values macOS reports about itself — no hardcoded release/EOL table
    // to keep updated as new macOS versions ship.
    static func osSupportStatus() -> StatusItem {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        let plist = NSDictionary(contentsOfFile: "/Library/Preferences/com.apple.SoftwareUpdate.plist")
        var lastCheckDate: Date?
        if let raw = plist?["LastFullSuccessfulDate"] as? String {
            lastCheckDate = isoDateParser.date(from: raw)
        } else if let date = plist?["LastFullSuccessfulDate"] as? Date {
            lastCheckDate = date
        }

        let detail: String
        if let lastCheckDate {
            detail = L10n.string(
                ko: "macOS \(versionString) · 마지막 업데이트 확인: \(displayDateFormatter.string(from: lastCheckDate))",
                en: "macOS \(versionString) · Last update check: \(displayDateFormatter.string(from: lastCheckDate))"
            )
        } else {
            detail = L10n.string(
                ko: "macOS \(versionString) · 마지막 업데이트 확인 기록 없음",
                en: "macOS \(versionString) · No update check on record"
            )
        }

        return StatusItem(
            title: L10n.string(ko: "OS 버전", en: "OS Version"),
            shortTitle: L10n.string(ko: "OS 업데이트", en: "OS Updates"),
            symbolName: "gearshape",
            detail: detail,
            ok: true
        )
    }

    static func gatekeeperStatus() -> StatusItem {
        let output = run("/usr/sbin/spctl", ["--status"])
        let enabled = output.contains("assessments enabled")
        return StatusItem(
            title: L10n.string(ko: "Gatekeeper (출처 확인)", en: "Gatekeeper (Source Verification)"),
            shortTitle: L10n.string(ko: "출처 확인", en: "App Source Check"),
            symbolName: "checkmark.seal",
            detail: enabled
                ? L10n.string(ko: "활성 · 미확인 개발자 앱 실행 차단", en: "Active · Blocks unidentified developer apps")
                : L10n.string(ko: "비활성", en: "Disabled"),
            ok: enabled,
            resolveURL: enabled ? nil : URL(string: "x-apple.systempreferences:com.apple.preference.security"),
            resolveTitle: L10n.string(ko: "보안 설정 열기", en: "Open Security Settings")
        )
    }

    static func fileVaultStatus() -> StatusItem {
        let output = run("/usr/bin/fdesetup", ["status"])
        let enabled = output.contains("FileVault is On")
        return StatusItem(
            title: L10n.string(ko: "FileVault (디스크 암호화)", en: "FileVault (Disk Encryption)"),
            shortTitle: L10n.string(ko: "디스크 암호화", en: "Disk Encryption"),
            symbolName: "lock.doc",
            detail: enabled
                ? L10n.string(ko: "활성 · 디스크 암호화됨", en: "Active · Disk is encrypted")
                : L10n.string(ko: "비활성", en: "Disabled"),
            ok: enabled,
            resolveURL: enabled ? nil : URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FDE"),
            resolveTitle: L10n.string(ko: "지금 켜기", en: "Turn On Now")
        )
    }

    static func firewallStatus() -> StatusItem {
        let output = run("/usr/libexec/ApplicationFirewall/socketfilterfw", ["--getglobalstate"])
        let enabled = output.contains("State = 1")
        return StatusItem(
            title: L10n.string(ko: "방화벽 (수신 연결 차단)", en: "Firewall (Inbound Connections)"),
            shortTitle: L10n.string(ko: "방화벽 및 네트워크", en: "Firewall & Network"),
            symbolName: "network",
            detail: enabled
                ? L10n.string(ko: "활성 · 허용되지 않은 수신 연결 차단", en: "Active · Blocks unapproved inbound connections")
                : L10n.string(ko: "비활성", en: "Disabled"),
            ok: enabled,
            resolveURL: enabled ? nil : URL(string: "x-apple.systempreferences:com.apple.preference.security?Firewall"),
            resolveTitle: L10n.string(ko: "지금 켜기", en: "Turn On Now")
        )
    }

    static func sipStatus() -> StatusItem {
        let output = run("/usr/bin/csrutil", ["status"])
        let enabled = output.contains("enabled")
        return StatusItem(
            title: "System Integrity Protection",
            shortTitle: L10n.string(ko: "디바이스 보안", en: "Device Security"),
            symbolName: "shield.lefthalf.filled",
            detail: enabled
                ? L10n.string(ko: "활성 · 시스템 파일 보호됨", en: "Active · System files protected")
                : L10n.string(ko: "비활성", en: "Disabled"),
            ok: enabled
        )
    }

    static func allStatuses() -> [StatusItem] {
        [osSupportStatus(), xprotectStatus(), gatekeeperStatus(), firewallStatus(), fileVaultStatus(), sipStatus()]
    }
}
