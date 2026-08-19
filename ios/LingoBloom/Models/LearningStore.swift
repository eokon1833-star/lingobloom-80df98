import Foundation
import Observation

@available(iOS 17.0, *)
struct LearningLesson: Identifiable, Codable, Hashable {
    enum State: String, Codable {
        case completed
        case active
        case locked
    }

    let id: String
    let title: String
    let subtitle: String
    let glyph: String
    var state: State
}

@available(iOS 17.0, *)
struct LessonPrompt: Identifiable, Hashable {
    let id: String
    let question: String
    let helper: String
    let options: [String]
    let correctOption: String
    let glyph: String
}

@available(iOS 17.0, *)
struct LanguageChoice: Identifiable, Hashable {
    let id: String
    let name: String
    let nativeName: String
    let symbol: String
}

@available(iOS 17.0, *)
@Observable
final class LearningStore {
    private enum Keys {
        static let languageID = "lingobloom.languageID"
        static let xp = "lingobloom.xp"
        static let streak = "lingobloom.streak"
        static let dailyGoal = "lingobloom.dailyGoal"
        static let minutesToday = "lingobloom.minutesToday"
        static let completedIDs = "lingobloom.completedIDs"
    }

    var selectedLanguageID: String
    var xp: Int
    var streakDays: Int
    var dailyGoalMinutes: Int
    var minutesToday: Int
    var lessons: [LearningLesson]

    let prompts: [LessonPrompt] = [
        LessonPrompt(id: "p1", question: "Choose the Spanish for “hello”", helper: "Tap the best answer.", options: ["Hola", "Gracias", "Adiós", "Por favor"], correctOption: "Hola", glyph: "hand.wave.fill"),
        LessonPrompt(id: "p2", question: "What does “gracias” mean?", helper: "Pick the matching meaning.", options: ["Please", "Thank you", "Good night", "Friend"], correctOption: "Thank you", glyph: "sparkles"),
        LessonPrompt(id: "p3", question: "Complete the phrase", helper: "Choose the word that fits.", options: ["Buenos días", "Buenas noches", "Hasta luego", "Lo siento"], correctOption: "Buenos días", glyph: "sun.max.fill")
    ]

    let languages: [LanguageChoice] = [
        LanguageChoice(id: "spanish", name: "Spanish", nativeName: "Español", symbol: "🇪🇸"),
        LanguageChoice(id: "french", name: "French", nativeName: "Français", symbol: "🇫🇷"),
        LanguageChoice(id: "japanese", name: "Japanese", nativeName: "日本語", symbol: "🇯🇵"),
        LanguageChoice(id: "korean", name: "Korean", nativeName: "한국어", symbol: "🇰🇷"),
        LanguageChoice(id: "italian", name: "Italian", nativeName: "Italiano", symbol: "🇮🇹"),
        LanguageChoice(id: "german", name: "German", nativeName: "Deutsch", symbol: "🇩🇪"),
        LanguageChoice(id: "portuguese", name: "Portuguese", nativeName: "Português", symbol: "🇧🇷"),
        LanguageChoice(id: "arabic", name: "Arabic", nativeName: "العربية", symbol: "🇸🇦"),
        LanguageChoice(id: "hindi", name: "Hindi", nativeName: "हिन्दी", symbol: "🇮🇳"),
        LanguageChoice(id: "mandarin", name: "Mandarin Chinese", nativeName: "中文", symbol: "🇨🇳"),
        LanguageChoice(id: "swahili", name: "Swahili", nativeName: "Kiswahili", symbol: "🇰🇪"),
        LanguageChoice(id: "turkish", name: "Turkish", nativeName: "Türkçe", symbol: "🇹🇷")
    ]

    var selectedLanguage: LanguageChoice {
        languages.first(where: { $0.id == selectedLanguageID }) ?? languages[0]
    }

    var activeLesson: LearningLesson? {
        lessons.first(where: { $0.state == .active })
    }

    var completedCount: Int {
        lessons.filter { $0.state == .completed }.count
    }

    var dailyProgress: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(Double(minutesToday) / Double(dailyGoalMinutes), 1)
    }

    init() {
        let defaults = UserDefaults.standard
        selectedLanguageID = defaults.string(forKey: Keys.languageID) ?? "spanish"
        xp = defaults.object(forKey: Keys.xp) as? Int ?? 280
        streakDays = defaults.object(forKey: Keys.streak) as? Int ?? 7
        dailyGoalMinutes = defaults.object(forKey: Keys.dailyGoal) as? Int ?? 10
        minutesToday = defaults.object(forKey: Keys.minutesToday) as? Int ?? 8
        let savedCompletedIDs = Set(defaults.stringArray(forKey: Keys.completedIDs) ?? ["basics", "people", "food"])
        lessons = Self.makeLessons(completedIDs: savedCompletedIDs)
    }

    func chooseLanguage(_ language: LanguageChoice) {
        selectedLanguageID = language.id
        lessons = Self.makeLessons(completedIDs: [])
        minutesToday = 0
        persist()
    }

    func completeCurrentLesson() {
        guard let activeIndex = lessons.firstIndex(where: { $0.state == .active }) else { return }
        lessons[activeIndex].state = .completed
        if lessons.indices.contains(activeIndex + 1) {
            lessons[activeIndex + 1].state = .active
        }
        xp += 24
        minutesToday += 3
        persist()
    }

    func updateDailyGoal(to minutes: Int) {
        dailyGoalMinutes = minutes
        persist()
    }

    func resetDemoProgress() {
        xp = 280
        streakDays = 7
        dailyGoalMinutes = 10
        minutesToday = 8
        selectedLanguageID = "spanish"
        lessons = Self.makeLessons(completedIDs: ["basics", "people", "food"])
        persist()
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(selectedLanguageID, forKey: Keys.languageID)
        defaults.set(xp, forKey: Keys.xp)
        defaults.set(streakDays, forKey: Keys.streak)
        defaults.set(dailyGoalMinutes, forKey: Keys.dailyGoal)
        defaults.set(minutesToday, forKey: Keys.minutesToday)
        defaults.set(lessons.filter { $0.state == .completed }.map(\.id), forKey: Keys.completedIDs)
    }

    private static func makeLessons(completedIDs: Set<String>) -> [LearningLesson] {
        let content: [(String, String, String, String)] = [
            ("basics", "Basics 1", "Greetings", "hand.wave.fill"),
            ("people", "Basics 2", "People", "person.2.fill"),
            ("food", "Basics 3", "Food", "fork.knife"),
            ("cafe", "Cafe chat", "Order with confidence", "cup.and.saucer.fill"),
            ("places", "Getting around", "Places", "map.fill"),
            ("family", "Family talk", "Connections", "house.fill"),
            ("review", "Quick review", "Keep it fresh", "arrow.triangle.2.circlepath"),
            ("stories", "Mini story", "Understand a scene", "book.closed.fill")
        ]
        let firstUnfinishedIndex = content.firstIndex(where: { !completedIDs.contains($0.0) }) ?? content.count
        return content.enumerated().map { index, item in
            let state: LearningLesson.State
            if completedIDs.contains(item.0) {
                state = .completed
            } else if index == firstUnfinishedIndex {
                state = .active
            } else {
                state = .locked
            }
            return LearningLesson(id: item.0, title: item.1, subtitle: item.2, glyph: item.3, state: state)
        }
    }
}
