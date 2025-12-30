import SwiftUI
import SwiftData
import Charts

// MARK: - MAIN TAB
struct MainView: View {
    @StateObject private var controller: LaughController
    init(context: ModelContext) { _controller = StateObject(wrappedValue: LaughController(context: context)) }
    
    var body: some View {
        TabView {
            HomeView(controller: controller).tabItem { Label("Home", systemImage: "face.smiling") }
            JournalView(controller: controller).tabItem { Label("Journal", systemImage: "book") }
            StatsView(controller: controller).tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            AchievementsView(controller: controller).tabItem { Label("Awards", systemImage: "trophy.fill") } // <--- NEW TAB
            SettingsView(controller: controller).tabItem { Label("Settings", systemImage: "gear") }
        }
        .accentColor(.orange)
    }
}

// MARK: - 1. ANIMATED HOMEPAGE (With Moving Background)
struct HomeView: View {
    @ObservedObject var controller: LaughController
    @State private var showLogSheet = false
    @State private var isBreathing = false
    
    // Animation State for Background
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // --- CONTINUOUS BACKGROUND ANIMATION ---
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.3),
                    Color.orange.opacity(0.3),
                    Color.pink.opacity(0.2)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("LAUGHMETER").font(.caption).bold().tracking(2).foregroundColor(.gray)
                        Text("Good Vibes Only").font(.title3).bold()
                    }
                    Spacer()
                    // Streak Badge
                    HStack {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                        Text("\(controller.weeklyStreak)")
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.5)) // Semi-transparent
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Spacer()
                
                // --- THE PULSING ORB ---
                ZStack {
                    // Outer glow (breathing)
                    Circle()
                        .fill(Color.orange.opacity(0.3)) // Slightly stronger for contrast
                        .frame(width: 280, height: 280)
                        .scaleEffect(isBreathing ? 1.1 : 1.0)
                        .opacity(isBreathing ? 0.6 : 0.3)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isBreathing)
                    
                    // Middle ring
                    Circle()
                        .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                        .frame(width: 250, height: 250)
                    
                    // The Interactive Button
                    Button(action: {
                        SoundManager.shared.playClickSound()
                        showLogSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 220, height: 220)
                                .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            VStack(spacing: 5) {
                                Text("😂")
                                    .font(.system(size: 80))
                                    .shadow(radius: 5)
                                Text("TAP TO LOG")
                                    .font(.caption).bold().foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
                .onAppear { isBreathing = true }
                
                Spacer()
                
                // --- STATS GRID ---
                HStack(spacing: 15) {
                    // Daily Count
                    VStack {
                        Text("\(controller.dailyCount)")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Laughs Today").font(.caption).foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8)) // Glass effect
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    // Last Activity
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "clock").foregroundColor(.blue)
                            Text("Recent").font(.caption).bold().foregroundColor(.blue)
                        }
                        Text(controller.lastLaughTime)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("With: \(controller.topPerson)")
                            .font(.caption).foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8)) // Glass effect
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showLogSheet) {
            AddLaughSheet(controller: controller)
                .presentationDetents([.fraction(0.55)])
        }
    }
}

// MARK: - 2. LOG SHEET
struct AddLaughSheet: View {
    @ObservedObject var controller: LaughController
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedMood = "😂"
    @State private var person = ""
    
    let moods = ["😂", "🙂", "🤣", "🥹", "💀"]
    let quickPeople = ["Friends", "Partner", "Family", "Work", "Self"]
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
            Text("How was the laugh?").font(.headline)
            
            HStack(spacing: 15) {
                ForEach(moods, id: \.self) { mood in
                    Text(mood)
                        .font(.system(size: 45))
                        .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: selectedMood)
                        .onTapGesture {
                            selectedMood = mood
                            SoundManager.shared.playClickSound()
                        }
                }
            }
            .padding(.vertical, 10)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Who with?").font(.caption).bold().foregroundColor(.gray)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(quickPeople, id: \.self) { p in
                            Text(p)
                                .font(.subheadline).bold()
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(person == p ? Color.orange : Color.gray.opacity(0.1))
                                .foregroundColor(person == p ? .white : .primary)
                                .cornerRadius(20)
                                .onTapGesture { person = p }
                        }
                    }
                }
            }.padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                controller.logLaugh(mood: selectedMood, person: person.isEmpty ? nil : person, location: nil, note: nil)
                dismiss()
            }) {
                HStack { Text("Save & Smile"); Image(systemName: "face.smiling.inverse") }
                    .bold().font(.title3).frame(maxWidth: .infinity).padding()
                    .background(Color.orange).foregroundColor(.white).cornerRadius(15).shadow(radius: 5)
            }.padding()
        }
    }
}

// MARK: - 3. JOURNAL VIEW
struct JournalView: View {
    @ObservedObject var controller: LaughController
    @State private var viewMode = 0
    @Query(sort: \LaughEntry.timestamp, order: .reverse) var laughs: [LaughEntry]
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("View", selection: $viewMode) { Text("List").tag(0); Text("Calendar").tag(1) }.pickerStyle(.segmented).padding()
                if viewMode == 0 {
                    List {
                        ForEach(laughs) { laugh in
                            HStack {
                                Text(laugh.mood).font(.largeTitle)
                                VStack(alignment: .leading) {
                                    Text(laugh.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.gray)
                                    if let p = laugh.person { Text("With \(p)").font(.caption2).bold().foregroundColor(.blue) }
                                }
                            }
                        }
                        .onDelete { idx in idx.forEach { controller.deleteLaugh(laughs[$0]) } }
                    }
                } else {
                    CalendarView(controller: controller)
                }
            }.navigationTitle("Laugh Journal")
        }
    }
}

struct CalendarView: View {
    @ObservedObject var controller: LaughController
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    let days = ["S", "M", "T", "W", "T", "F", "S"]
    func daysInMonth() -> [Date?] {
        let c = Calendar.current
        let start = c.dateInterval(of: .month, for: Date())!.start
        let dayOne = c.component(.weekday, from: start)
        let total = c.range(of: .day, in: .month, for: Date())!.count
        var arr: [Date?] = Array(repeating: nil, count: dayOne - 1)
        for i in 0..<total { arr.append(c.date(byAdding: .day, value: i, to: start)) }
        return arr
    }
    var body: some View {
        ScrollView {
            VStack {
                HStack { ForEach(days, id: \.self) { d in Text(d).font(.caption).bold().frame(maxWidth: .infinity) } }
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<daysInMonth().count, id: \.self) { i in
                        if let date = daysInMonth()[i] {
                            let count = controller.laughsByDate[Calendar.current.startOfDay(for: date)] ?? 0
                            VStack {
                                Text("\(Calendar.current.component(.day, from: date))").font(.caption).foregroundColor(count > 0 ? .white : .primary)
                            }
                            .frame(height: 40).frame(maxWidth: .infinity)
                            .background(count > 0 ? Color.orange : Color.clear).cornerRadius(8)
                        } else { Text("") }
                    }
                }
            }.padding()
        }
    }
}

// MARK: - 4. STATS & SHARE
struct StatsView: View {
    @ObservedObject var controller: LaughController
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    ShareLink(item: generateShareImage(), preview: SharePreview("Joy Card", image: generateShareImage())) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15).fill(Color.blue.gradient)
                            HStack { Image(systemName: "square.and.arrow.up"); Text("Share Daily Joy Card").bold() }.foregroundColor(.white)
                        }.frame(height: 55).padding(.horizontal)
                    }
                    VStack(alignment: .leading) {
                        Text("Weekly Trend").font(.headline).padding(.horizontal)
                        Chart {
                            ForEach(controller.weeklyChartData.sorted(by: { $0.key < $1.key }), id: \.key) { date, count in
                                BarMark(x: .value("Day", date, unit: .day), y: .value("Laughs", count))
                                    .foregroundStyle(Color.orange.gradient)
                            }
                        }
                        .frame(height: 200).padding().background(Color.gray.opacity(0.05)).cornerRadius(15).padding(.horizontal)
                    }
                    HStack {
                        StatTile(title: "Best Partner", val: controller.topPerson, icon: "person.2.fill", color: .pink)
                        StatTile(title: "Best Place", val: controller.topLocation, icon: "mappin.and.ellipse", color: .green)
                    }.padding(.horizontal)
                }.navigationTitle("Insights").padding(.top)
            }
        }
    }
    @MainActor func generateShareImage() -> Image {
        let view = ShareCardView(count: controller.dailyCount, person: controller.topPerson)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage { return Image(uiImage: uiImage) }
        return Image(systemName: "xmark")
    }
}

// MARK: - 5. COMPONENTS
struct ShareCardView: View {
    let count: Int
    let person: String
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.orange, Color.red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 20) {
                Text("LAUGHMETER").font(.caption).bold().tracking(4).foregroundColor(.white.opacity(0.7)).padding(.top, 40)
                Spacer()
                Text("\(count)").font(.system(size: 130, weight: .heavy)).foregroundColor(.white).shadow(radius: 10)
                Text("Laughs Today").font(.title2).bold().foregroundColor(.white)
                VStack {
                    Text("HAPPIEST WITH").font(.caption).bold().foregroundColor(.white.opacity(0.8))
                    Text(person).font(.title).bold().foregroundColor(.white)
                }.padding().background(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.5), lineWidth: 1)).padding(.horizontal, 40)
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted)).font(.footnote).foregroundColor(.white.opacity(0.6)).padding(.bottom)
            }
        }.frame(width: 375, height: 650)
    }
}

struct StatTile: View {
    let title: String, val: String, icon: String, color: Color
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: icon).foregroundColor(color).font(.title2)
            Spacer()
            Text(title).font(.caption).foregroundColor(.gray)
            Text(val).font(.headline).lineLimit(1)
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading).frame(height: 100)
        .background(Color.white).cornerRadius(15).shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 6. SETTINGS
struct SettingsView: View {
    @ObservedObject var controller: LaughController
    var body: some View {
        NavigationStack {
            List {
                Section("Data") { ShareLink(item: controller.generateCSV()) { Label("Export CSV", systemImage: "arrow.down.doc") } }
                Section("About") {
                    Text("Version 1.1")
                    Text("LaughMeter with 30+ Achievements")
                }
            }.navigationTitle("Settings")
        }
    }
}
