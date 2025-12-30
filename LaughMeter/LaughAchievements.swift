import SwiftUI
import SwiftData

// MARK: - 1. DATA MODEL
struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    var isUnlocked: Bool
}

// MARK: - 2. LOGIC ENGINE
class AchievementEngine {
    
    static func calculate(laughs: [LaughEntry]) -> [Achievement] {
        let count = laughs.count
        let calendar = Calendar.current
        
        // Helper: Calculate streak
        // (Simplified logic: checks if there is at least 1 laugh today)
        let streak = laughs.filter { calendar.isDateInToday($0.timestamp) }.count > 0 ? 1 : 0
        
        // Helper: Counts by Context
        let homeCount = laughs.filter { ($0.location ?? "").lowercased().contains("home") }.count
        let workCount = laughs.filter { ($0.location ?? "").lowercased().contains("work") || ($0.location ?? "").lowercased().contains("office") }.count
        let friendCount = laughs.filter { ($0.person ?? "").lowercased().contains("friend") }.count
        let partnerCount = laughs.filter { ($0.person ?? "").lowercased().contains("partner") }.count
        
        // Helper: Time of Day
        let morningLaughs = laughs.filter {
            let hour = calendar.component(.hour, from: $0.timestamp)
            return hour >= 5 && hour < 12
        }.count
        
        let nightLaughs = laughs.filter {
            let hour = calendar.component(.hour, from: $0.timestamp)
            return hour >= 22 || hour < 4
        }.count

        // --- THE 30 ACHIEVEMENTS ---
        let list: [(id: String, title: String, desc: String, icon: String, col: Color, unlocked: Bool)] = [
            // Level 1: Basics
            ("1", "First Smile", "Log your first laugh", "🙂", .blue, count >= 1),
            ("2", "Giggle Rookie", "Log 10 laughs", "👶", .blue, count >= 10),
            ("3", "Chuckle Champ", "Log 50 laughs", "🥉", .green, count >= 50),
            ("4", "ROFL Master", "Log 100 laughs", "🥈", .orange, count >= 100),
            ("5", "Laugh Legend", "Log 500 laughs", "🥇", .purple, count >= 500),
            ("6", "Joy Junkie", "Log 1,000 laughs", "💎", .pink, count >= 1000),
            
            // Level 2: Context (People)
            ("7", "Social Butterfly", "Laugh with friends 5 times", "🦋", .pink, friendCount >= 5),
            ("8", "Squad Goals", "Laugh with friends 20 times", "👯‍♀️", .pink, friendCount >= 20),
            ("9", "Love & Laughs", "Laugh with partner 5 times", "❤️", .red, partnerCount >= 5),
            ("10", "Rom Com", "Laugh with partner 20 times", "🍿", .red, partnerCount >= 20),
            ("11", "Solo Smiler", "Log a laugh alone", "🧘", .indigo, laughs.contains { ($0.person ?? "").isEmpty || ($0.person ?? "").contains("Self") }),
            
            // Level 3: Context (Places)
            ("12", "Homebody", "5 laughs at Home", "🏡", .green, homeCount >= 5),
            ("13", "Home Hero", "50 laughs at Home", "🏰", .green, homeCount >= 50),
            ("14", "Office Clown", "Laugh at Work 5 times", "💼", .gray, workCount >= 5),
            ("15", "Nature Lover", "Laugh outside/park", "🌳", .green, laughs.contains { ($0.location ?? "").contains("Park") }),
            
            // Level 4: Time
            ("16", "Early Bird", "Laugh before noon (5 times)", "☀️", .yellow, morningLaughs >= 5),
            ("17", "Night Owl", "Laugh after 10 PM (5 times)", "🌙", .indigo, nightLaughs >= 5),
            ("18", "Lunch Break", "Laugh between 12-1 PM", "🍔", .orange, laughs.contains { calendar.component(.hour, from: $0.timestamp) == 12 }),
            ("19", "Weekend Warrior", "Laugh on Sat or Sun", "🎉", .purple, laughs.contains { calendar.isDateInWeekend($0.timestamp) }),
            
            // Level 5: Moods
            ("20", "Tears of Joy", "Log '😂' mood 10 times", "😂", .cyan, laughs.filter { $0.mood == "😂" }.count >= 10),
            ("21", "Subtle Grin", "Log '🙂' mood 10 times", "🙂", .mint, laughs.filter { $0.mood == "🙂" }.count >= 10),
            ("22", "Dead Funny", "Log '💀' mood", "💀", .gray, laughs.contains { $0.mood == "💀" }),
            ("23", "Heart Warmed", "Log '🥹' mood", "🥹", .pink, laughs.contains { $0.mood == "🥹" }),
            
            // Level 6: Habits
            ("24", "Streak Starter", "Laugh today (Start streak)", "🔥", .orange, streak >= 1),
            ("25", "Double Digit Day", "10 laughs in one day", "🚀", .red, laughs.filter { calendar.isDateInToday($0.timestamp) }.count >= 10),
            ("26", "Note Taker", "Add notes to 5 laughs", "📝", .yellow, laughs.filter { ($0.note ?? "").count > 0 }.count >= 5),
            ("27", "Detail Orientated", "Add notes to 20 laughs", "✍️", .yellow, laughs.filter { ($0.note ?? "").count > 0 }.count >= 20),
            ("28", "Context King", "Add person/location to 10 laughs", "🏷️", .blue, laughs.filter { $0.person != nil || $0.location != nil }.count >= 10),
            ("29", "Explorer", "Log laughs in 3 diff places", "🗺️", .green, Set(laughs.compactMap { $0.location }).count >= 3),
            ("30", "The Century", "100 Laughs total. You made it.", "💯", .red, count >= 100)
        ]
        
        return list.map { Achievement(id: $0.id, title: $0.title, description: $0.desc, icon: $0.icon, color: $0.col, isUnlocked: $0.unlocked) }
    }
}

// MARK: - 3. NEW SQUARE CARD VIEW
struct AchievementsView: View {
    @ObservedObject var controller: LaughController
    
    // 3 Columns Grid
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    // Header Stats
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Your Trophy Case")
                                .font(.headline).foregroundColor(.gray)
                            Text("\(controller.badges.filter { $0.isUnlocked }.count) / \(controller.badges.count) Unlocked")
                                .font(.title2).bold()
                        }
                        Spacer()
                        Image(systemName: "trophy.fill")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                            .shadow(color: .orange, radius: 10)
                    }
                    .padding()
                    
                    // The Grid
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(controller.badges) { badge in
                            AchievementCard(badge: badge)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Achievements")
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

struct AchievementCard: View {
    let badge: Achievement
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    badge.isUnlocked
                    ? LinearGradient(colors: [badge.color.opacity(0.2), badge.color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            badge.isUnlocked ? badge.color.opacity(0.5) : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
            
            VStack(spacing: 10) {
                // Icon
                if badge.isUnlocked {
                    Text(badge.icon)
                        .font(.system(size: 40))
                        .shadow(color: badge.color.opacity(0.5), radius: 5)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.3))
                }
                
                // Text
                VStack(spacing: 2) {
                    Text(badge.title)
                        .font(.caption)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(badge.isUnlocked ? .primary : .gray)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    if badge.isUnlocked {
                        Text(badge.description)
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
            .padding(8)
        }
        .aspectRatio(1, contentMode: .fit) // Force Square
        .grayscale(badge.isUnlocked ? 0 : 1.0)
        .opacity(badge.isUnlocked ? 1.0 : 0.6)
    }
}
