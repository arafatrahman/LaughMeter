import Foundation
import SwiftData
import SwiftUI
import Combine
import UserNotifications
import AVFoundation

// MARK: - 1. THE MODELS (Data)
@Model
class LaughEntry {
    var id: UUID
    var timestamp: Date
    var mood: String
    var person: String?
    var location: String?
    var note: String?
    
    init(mood: String = "😄", person: String? = nil, location: String? = nil, note: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.mood = mood
        self.person = person
        self.location = location
        self.note = note
    }
}

// MARK: - 2. QUOTE MANAGER (New)
struct QuoteManager {
    static let quotes = [
        "Laughter is the shock absorber that eases the blows of life.",
        "A day without laughter is a day wasted. – Charlie Chaplin",
        "Laughter is an instant vacation. – Milton Berle",
        "Against the assault of laughter, nothing can stand. – Mark Twain",
        "If you’re too busy to laugh, you are too busy.",
        "Smile, it confuses people.",
        "Laughter is the closest distance between two people.",
        "There is nothing in the world so irresistibly contagious as laughter.",
        "Optimist: someone who figures that taking a step backward after taking a step forward is not a disaster, it's more like a cha-cha.",
        "Laugh at your problems, everyone else does."
    ]
    
    static func getDailyQuote() -> String {
        // Pick a quote based on the day of the year so it stays same for the whole day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % quotes.count
        return quotes[index]
    }
}

// MARK: - 3. SOUND MANAGER
class SoundManager {
    static let shared = SoundManager()
    var audioPlayer: AVAudioPlayer?
    
    func playLaughSound() {
        if let path = Bundle.main.path(forResource: "laugh", ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.play()
                return
            } catch { print("Error playing custom sound") }
        }
        AudioServicesPlaySystemSound(1057)
    }
    
    func playClickSound() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - 4. THE CONTROLLER (Logic)
@MainActor
class LaughController: ObservableObject {
    var modelContext: ModelContext
    
    // --- UI State ---
    @Published var dailyCount: Int = 0
    @Published var weeklyStreak: Int = 0
    
    // --- Stats ---
    @Published var topPerson: String = "---"
    @Published var topLocation: String = "---"
    @Published var lastLaughTime: String = "Start your day!"
    @Published var weeklyChartData: [Date: Int] = [:]
    
    // --- Calendar Helper ---
    @Published var laughsByDate: [Date: Int] = [:]
    
    // --- Achievements ---
    @Published var badges: [Achievement] = []
    
    // --- Custom People Management ---
    @Published var people: [String] = []
    
    init(context: ModelContext) {
        self.modelContext = context
        
        // Load custom people or set defaults
        let savedPeople = UserDefaults.standard.stringArray(forKey: "SavedPeople")
        self.people = savedPeople ?? ["Friends", "Partner", "Family", "Work", "Self"]
        
        requestNotificationPermission()
        refreshAll()
    }
    
    // MARK: - Core Actions
    func logLaugh(mood: String, person: String?, location: String?, note: String?) {
        let newLaugh = LaughEntry(mood: mood, person: person, location: location, note: note)
        modelContext.insert(newLaugh)
        try? modelContext.save()
        SoundManager.shared.playLaughSound()
        refreshAll()
    }
    
    func updateLaugh(_ laugh: LaughEntry, mood: String, person: String?) {
        laugh.mood = mood
        laugh.person = person
        try? modelContext.save()
        refreshAll()
    }
    
    func deleteLaugh(_ laugh: LaughEntry) {
        modelContext.delete(laugh)
        try? modelContext.save()
        refreshAll()
    }
    
    // MARK: - People Management Actions
    func addPerson(_ name: String) {
        guard !name.isEmpty, !people.contains(name) else { return }
        people.append(name)
        savePeople()
    }
    
    func deletePerson(at offsets: IndexSet) {
        people.remove(atOffsets: offsets)
        savePeople()
    }
    
    func movePerson(from source: IndexSet, to destination: Int) {
        people.move(fromOffsets: source, toOffset: destination)
        savePeople()
    }
    
    private func savePeople() {
        UserDefaults.standard.set(people, forKey: "SavedPeople")
    }
    
    // MARK: - Data Refresh & Analysis
    func refreshAll() {
        let descriptor = FetchDescriptor<LaughEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        do {
            let laughs = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            
            // 1. Basic Counts
            self.dailyCount = laughs.filter { calendar.isDateInToday($0.timestamp) }.count
            self.weeklyStreak = self.dailyCount > 0 ? 1 : 0
            
            // 2. Last Laugh
            if let last = laughs.first, calendar.isDateInToday(last.timestamp) {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                let timeStr = formatter.localizedString(for: last.timestamp, relativeTo: Date())
                self.lastLaughTime = timeStr
            } else {
                self.lastLaughTime = "None yet"
            }
            
            // 3. Top Stats
            let peopleList = laughs.compactMap { $0.person }
            self.topPerson = self.getMostFrequent(arr: peopleList) ?? "---"
            let places = laughs.compactMap { $0.location }
            self.topLocation = self.getMostFrequent(arr: places) ?? "---"
            
            // 4. Chart Data
            var chartData: [Date: Int] = [:]
            let today = Date()
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    let start = calendar.startOfDay(for: date)
                    let count = laughs.filter { calendar.isDate( $0.timestamp, inSameDayAs: date) }.count
                    chartData[start] = count
                }
            }
            self.weeklyChartData = chartData
            
            // 5. Calendar Map
            var dateMap: [Date: Int] = [:]
            for laugh in laughs {
                let start = calendar.startOfDay(for: laugh.timestamp)
                dateMap[start, default: 0] += 1
            }
            self.laughsByDate = dateMap
            
            // 6. Badges
            self.badges = AchievementEngine.calculate(laughs: laughs)
            
        } catch { print("Error fetching data") }
    }
    
    func generateCSV() -> String {
        let descriptor = FetchDescriptor<LaughEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        guard let laughs = try? modelContext.fetch(descriptor) else { return "Error" }
        var csv = "Date,Mood,Person,Location\n"
        for l in laughs {
            csv += "\(l.timestamp),\(l.mood),\(l.person ?? ""),\(l.location ?? "")\n"
        }
        return csv
    }
    
    private func getMostFrequent(arr: [String]) -> String? {
        let counts = arr.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
