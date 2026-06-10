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
    private static let arabicTranslations: [String: String] = [
        "Paused today": "متوقف اليوم",
        "Outside reminder window": "خارج فترة التذكير",
        "Next reminder unavailable": "التذكير التالي غير متوفر",
        "Notifications disabled": "الإشعارات معطلة",
        "Enable notifications in System Settings": "تمكين الإشعارات في إعدادات النظام",
        "Drink now": "اشرب الآن",
        "Snooze 30 minutes": "غفوة 30 دقيقة",
        "Resume reminders": "استئناف التذكيرات",
        "Pause today": "إيقاف مؤقت اليوم",
        "Settings": "الإعدادات",
        "Quit": "إنهاء",
        "General": "عام",
        "Run automatically at login": "التشغيل تلقائيًا عند تسجيل الدخول",
        "Goal": "الهدف",
        "Interval": "الفترة",
        "Reminder Interval": "فترة التذكير",
        "Custom interval (minutes)": "فترة مخصصة (بالدقائق)",
        "Reminder Time Range": "النطاق الزمني للتذكير",
        "Start Time": "وقت البدء",
        "End Time": "وقت الانتهاء",
        "Reminder Mode": "وضع التذكير",
        "System Notification": "إشعارات النظام",
        "Enter a valid custom interval.": "أدخل فترة مخصصة صالحة.",
        "Language": "اللغة",
        "It's time to drink": "حان وقت الشرب",
        "water or whatever": "الماء أو أي شيء آخر",
        "Next reminder: %@": "التذكير التالي: %@",
        "Daily Goal: %.1f liters": "الهدف اليومي: %.1f لتر",
        "Drink Portion: %d ml": "كمية الشرب: %d مل",
        "Drink Reminder": "مذكّر الشرب",
        "Interval must be at least 5 minutes.": "يجب أن تكون الفترة ٥ دقائق على الأقل.",
        "End time must be later than start time.": "يجب أن يكون وقت الانتهاء بعد وقت البدء."
    ]

    static func string(_ key: String, lang: AppLanguage) -> String {
        guard lang == .arabic else { return key }
        return arabicTranslations[key] ?? key
    }
}

extension String {
    func localized(_ lang: AppLanguage) -> String {
        Localizer.string(self, lang: lang)
    }
}
