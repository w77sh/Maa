import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        }
    }
}

enum Localizer {
    static func string(_ key: String, lang: AppLanguage) -> String {
        guard let path = Bundle.main.path(forResource: lang.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension String {
    func localized(_ lang: AppLanguage) -> String {
        Localizer.string(self, lang: lang)
    }
}
