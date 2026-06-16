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
        "End time must be later than start time.": "يجب أن يكون وقت الانتهاء بعد وقت البدء.",
        "Popup Window": "نافذة منبثقة",
        "Consumed: %d ml / %d ml": "الكمية المستهلكة: %d مل / %d مل",
        "It's time to drink water!": "حان وقت شرب الماء!",
        "Close": "إغلاق",
        "Snooze": "غفوة",
        "Drink Now": "اشرب الآن",
        "Statistics": "الإحصائيات",
        "Drinking Statistics": "إحصائيات الشرب",
        "No data available yet.": "لا توجد بيانات متاحة بعد.",
        "Average Daily Intake": "متوسط الشرب اليومي",
        "Total Consumed": "إجمالي ما تم شربه",
        "Best Day": "أفضل يوم",
        "All Time": "كل الوقت",
        "Last 7 Days": "آخر ٧ أيام",
        "Last 30 Days": "آخر ٣٠ يوماً",
        "Time Range": "النطاق الزمني",
        "Goal Reached": "تم الوصول للهدف",
        "Check for updates": "التحقق من التحديثات",
        "Update Check Failed": "فشل التحقق من التحديث",
        "Could not connect to GitHub.": "تعذر الاتصال بخوادم التحديث.",
        "Update Available": "تحديث متاح",
        "A new version (%@) is available!": "يتوفر إصدار جديد (%@)!",
        "Download": "تحميل",
        "Cancel": "إلغاء",
        "Up to Date": "مُحدّث",
        "You have the latest version.": "لديك أحدث إصدار.",
        "Invalid response from GitHub.": "استجابة غير صالحة من الخادم.",
        "Error parsing response.": "خطأ في قراءة البيانات.",
        "OK": "حسناً"
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
