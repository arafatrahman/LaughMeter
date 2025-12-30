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

// MARK: - 2. QUOTE MANAGER (100 Unique Funny & Motivated Thoughts)
struct QuoteManager {
    static let quotes = [
        "Be a cupcake in a world of muffins.",
        "Run like your phone is at 1%.",
        "If you fall, I’ll be there. – Floor",
        "Sucking at something is the first step to being sorta good at something.",
        "Don't stop when you're tired. Stop when you're done (or when the pizza arrives).",
        "Confidence is 10% hard work and 90% delusion.",
        "Be the person your dog thinks you are.",
        "I’m not lazy, I’m on energy saving mode.",
        "Life is short. Smile while you still have teeth.",
        "You can’t make everyone happy. You aren’t a jar of Nutella.",
        "If at first you don't succeed, then skydiving definitely isn't for you.",
        "My bed is a magical place where I suddenly remember everything I forgot to do.",
        "Do not take life too seriously. You will never get out of it alive.",
        "I walk around like everything is fine, but deep down, inside my shoe, my sock is sliding off.",
        "Being an adult is just googling how to do stuff.",
        "I am a limited edition. There is only one me.",
        "The elevator to success is out of order. You’ll have to use the stairs.",
        "Believe in yourself. An avocado can become guacamole, so you can be anything.",
        "Everything is figureoutable.",
        "Drink some coffee and pretend you know what you're doing.",
        "Life is a shipwreck, but we must not forget to sing in the lifeboats.",
        "Throw kindness around like confetti.",
        "Be happy. It drives people crazy.",
        "If you think you are too small to be effective, you have never been in bed with a mosquito.",
        "Don’t grow up. It’s a trap.",
        "Follow your heart, but take your brain with you.",
        "Strive for progress, not perfection.",
        "Make today so awesome that yesterday gets jealous.",
        "A diamond is merely a lump of coal that did well under pressure.",
        "I’m not bossy, I just have better ideas.",
        "Life is like a camera. Focus on what’s important. Capture the good times.",
        "Don't worry, be happy! (And maybe drink some water).",
        "You’re only human. You don’t have to have it together every minute of every day.",
        "It’s okay to be a glowstick: sometimes we have to break before we shine.",
        "Bad decisions make good stories.",
        "If you see someone without a smile, give them one of yours.",
        "Don't give up on your dreams. Keep sleeping.",
        "Stressed is just desserts spelled backwards.",
        "Nothing is impossible. The word itself says 'I'm possible'!",
        "Work hard in silence, let your success be the noise.",
        "Hustle until your haters ask if you're hiring.",
        "Be the energy you want to attract.",
        "Today is a good day to have a good day.",
        "Your vibe attracts your tribe.",
        "Keep your heels, head, and standards high.",
        "The best revenge is massive success.",
        "Dream big. Work hard. Stay humble.",
        "Do something today that your future self will thank you for.",
        "Success is the only option.",
        "You are capable of amazing things.",
        "Don't wait for opportunity. Create it.",
        "Great things never come from comfort zones.",
        "Wake up with determination. Go to bed with satisfaction.",
        "Happiness is an inside job.",
        "Positive mind. Positive vibes. Positive life.",
        "Focus on the good.",
        "Enjoy the little things.",
        "Collect moments, not things.",
        "Life is tough, but so are you.",
        "Believe you can and you're halfway there.",
        "Every day is a fresh start.",
        "Be the change you wish to see in the world.",
        "Shine bright like a diamond.",
        "You got this!",
        "Stay positive, work hard, make it happen.",
        "Inhale confidence. Exhale doubt.",
        "Be a warrior, not a worrier.",
        "Stars can't shine without darkness.",
        "Mistakes are proof that you are trying.",
        "Never give up on something you really want.",
        "Success starts with self-discipline.",
        "Motivation is what gets you started. Habit is what keeps you going.",
        "Don't look back. You're not going that way.",
        "Your only limit is your mind.",
        "It always seems impossible until it's done.",
        "The future belongs to those who believe in the beauty of their dreams.",
        "Start where you are. Use what you have. Do what you can.",
        "Success doesn't just find you. You have to go out and get it.",
        "Work until your idols become your rivals.",
        "Don't stop until you're proud.",
        "Limit your 'always' and your 'nevers'.",
        "It’s a slow process, but quitting won’t speed it up.",
        "Focus on your goal. Don't look in any direction but ahead.",
        "Action is the foundational key to all success.",
        "Success is not final, failure is not fatal: it is the courage to continue that counts.",
        "If you want to fly, give up everything that weighs you down.",
        "A year from now you will wish you had started today.",
        "The best way to predict the future is to create it.",
        "Do what you love, love what you do.",
        "Live every day as if it were your last.",
        "Be so good they can't ignore you.",
        "Success is 99% attitude and 1% aptitude.",
        "Turn your can’ts into cans and your dreams into plans.",
        "Fall seven times, stand up eight.",
        "The expert in anything was once a beginner.",
        "Don't let yesterday take up too much of today.",
        "You are stronger than you think.",
        "One day or day one. You decide.",
        "Laughter is the best medicine... unless you have diarrhea."
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
    
    // --- NEW: Play Custom Smile Sound ---
    func playSmileSound() {
        // Ensure you have a file named "smile.mp3" in your project bundle
        if let path = Bundle.main.path(forResource: "smile", ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.play()
            } catch { print("Error playing smile sound") }
        } else {
            // Fallback if file missing: simple click sound
            playClickSound()
        }
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
