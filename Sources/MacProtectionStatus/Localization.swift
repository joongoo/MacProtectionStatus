import Foundation

enum AppLanguage: String, CaseIterable {
    case korean = "ko"
    case english = "en"

    var displayName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        }
    }
}

extension Notification.Name {
    static let appLanguageChanged = Notification.Name("appLanguageChanged")
}

enum L10n {
    private static let defaultsKey = "AppLanguage"

    static var current: AppLanguage {
        get {
            if let raw = UserDefaults.standard.string(forKey: defaultsKey), let lang = AppLanguage(rawValue: raw) {
                return lang
            }
            return Locale.preferredLanguages.first?.hasPrefix("ko") == true ? .korean : .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
            NotificationCenter.default.post(name: .appLanguageChanged, object: nil)
        }
    }

    static func string(ko: String, en: String) -> String {
        current == .korean ? ko : en
    }
}
