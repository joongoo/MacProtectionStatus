import Foundation

struct StatusItem {
    let title: String
    let detail: String
    let ok: Bool
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
            return StatusItem(title: "XProtect", detail: "상태를 확인할 수 없음", ok: false)
        }
        return StatusItem(title: "XProtect (악성코드 검사)", detail: "활성 · 정의 버전 \(version)", ok: true)
    }

    static func gatekeeperStatus() -> StatusItem {
        let output = run("/usr/sbin/spctl", ["--status"])
        let enabled = output.contains("assessments enabled")
        return StatusItem(
            title: "Gatekeeper (출처 확인)",
            detail: enabled ? "활성 · 미확인 개발자 앱 실행 차단" : "비활성",
            ok: enabled
        )
    }

    static func fileVaultStatus() -> StatusItem {
        let output = run("/usr/bin/fdesetup", ["status"])
        let enabled = output.contains("FileVault is On")
        return StatusItem(
            title: "FileVault (디스크 암호화)",
            detail: enabled ? "활성 · 디스크 암호화됨" : "비활성",
            ok: enabled
        )
    }

    static func sipStatus() -> StatusItem {
        let output = run("/usr/bin/csrutil", ["status"])
        let enabled = output.contains("enabled")
        return StatusItem(
            title: "System Integrity Protection",
            detail: enabled ? "활성 · 시스템 파일 보호됨" : "비활성",
            ok: enabled
        )
    }

    static func allStatuses() -> [StatusItem] {
        [xprotectStatus(), gatekeeperStatus(), fileVaultStatus(), sipStatus()]
    }
}
