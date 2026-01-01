import SwiftUI
import SwiftData
import Charts

// MARK: - MAIN TAB
struct MainView: View {
    @StateObject private var controller: LaughController
    @State private var showSplash = true // STATE FOR SPLASH SCREEN
    
    init(context: ModelContext) { _controller = StateObject(wrappedValue: LaughController(context: context)) }
    
    var body: some View {
        ZStack {
            // 1. MAIN APP CONTENT
            TabView {
                HomeView(controller: controller).tabItem { Label("Home", systemImage: "face.smiling") }
                JournalView(controller: controller).tabItem { Label("Journal", systemImage: "book") }
                StatsView(controller: controller).tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                AchievementsView(controller: controller).tabItem { Label("Awards", systemImage: "trophy.fill") }
                SettingsView(controller: controller).tabItem { Label("Settings", systemImage: "gear") }
            }
            .accentColor(.orange)
            
            // 2. ACHIEVEMENT POPUP OVERLAY
            if controller.showAchievementPopup, let badge = controller.newlyUnlockedBadge {
                AchievementPopup(badge: badge) {
                    withAnimation {
                        controller.showAchievementPopup = false
                        controller.newlyUnlockedBadge = nil
                    }
                }
            }
            
            // 3. SPLASH SCREEN OVERLAY
            if showSplash {
                SplashScreen(showSplash: $showSplash)
                    .transition(.opacity)
                    .zIndex(100) // Keeps it on top
            }
        }
    }
}

// MARK: - SPLASH SCREEN
struct SplashScreen: View {
    @Binding var showSplash: Bool
    @State private var scale = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            Color.orange.ignoresSafeArea()
            LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Image("AppLogo").resizable().scaledToFit().frame(width: 200, height: 200).shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
                }.scaleEffect(scale)
                VStack(spacing: 5) {
                    Text("LaughMeter").font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundColor(.white).shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    Text("Daily Dose of Joy").font(.headline).foregroundColor(.white.opacity(0.9)).tracking(2)
                }.padding(.top, 10).opacity(opacity)
                Spacer()
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.5).padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { scale = 1.0; opacity = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation(.easeOut(duration: 0.4)) { showSplash = false } }
        }
    }
}

// MARK: - FIREWORKS
struct AchievementPopup: View {
    let badge: Achievement
    var onDismiss: () -> Void
    @State private var scale: CGFloat = 0.5; @State private var opacity: Double = 0.0
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea().onTapGesture { onDismiss() }
            FireworksView()
            VStack(spacing: 20) {
                Text("🎉 CONGRATULATIONS! 🎉").font(.headline).tracking(2).foregroundColor(.white).padding(.top, 10)
                ZStack {
                    Circle().fill(badge.color.gradient).frame(width: 120, height: 120).shadow(color: badge.color.opacity(0.6), radius: 20)
                    Text(badge.icon).font(.system(size: 60))
                }
                VStack(spacing: 8) {
                    Text(badge.title).font(.title).fontWeight(.heavy).foregroundColor(.white)
                    Text(badge.description).font(.body).multilineTextAlignment(.center).foregroundColor(.white.opacity(0.8)).padding(.horizontal)
                }
                Button(action: onDismiss) {
                    Text("AWESOME!").font(.headline).foregroundColor(badge.color).padding(.horizontal, 30).padding(.vertical, 12).background(Color.white).cornerRadius(25).shadow(radius: 5)
                }.padding(.bottom, 20)
            }.padding(20).background(Material.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 25)).overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.3), lineWidth: 1)).padding(30).scaleEffect(scale).opacity(opacity).onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { scale = 1.0; opacity = 1.0 } }
        }.zIndex(100)
    }
}
struct FireworksView: View {
    let colors: [Color] = [.red, .yellow, .blue, .green, .purple, .orange]
    var body: some View { ZStack { ForEach(0..<4) { index in Explosion(delay: Double(index) * 0.2, color: colors.randomElement()!).offset(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -200...0)) } } }
}
struct Explosion: View {
    let delay: Double; let color: Color; @State private var animate = false
    var body: some View { ZStack { ForEach(0..<12) { i in Circle().fill(color).frame(width: 8, height: 8).modifier(ParticleModifier(angle: Double(i) * 30, animate: animate)).opacity(animate ? 0 : 1) } }.onAppear { withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(delay)) { animate = true } } }
}
struct ParticleModifier: GeometryEffect {
    var angle: Double; var animate: Bool; var animatableData: Double { get { animate ? 1 : 0 } set { } }
    func effectValue(size: CGSize) -> ProjectionTransform { let distance = animate ? 150.0 : 0.0; let x = distance * cos(angle * .pi / 180); let y = distance * sin(angle * .pi / 180); return ProjectionTransform(CGAffineTransform(translationX: x, y: y)) }
}

// MARK: - 1. HOME VIEW
struct HomeView: View {
    @ObservedObject var controller: LaughController
    @State private var showLogSheet = false
    @State private var isBreathing = false
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2), Color.pink.opacity(0.1)], startPoint: animateGradient ? .topLeading : .bottomLeading, endPoint: animateGradient ? .bottomTrailing : .topTrailing).ignoresSafeArea().onAppear { withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) { animateGradient.toggle() } }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    Text("Daily Dose of Joy").font(.caption).bold().textCase(.uppercase).tracking(2).foregroundColor(.secondary)
                    Text("\"\(QuoteManager.getDailyQuote())\"").font(.body).italic().multilineTextAlignment(.center).padding(.horizontal).foregroundColor(.primary.opacity(0.8))
                    
                    if controller.topPerson != "---" {
                        HStack(spacing: 6) { Image(systemName: "crown.fill").font(.caption).foregroundColor(.yellow).shadow(color: .orange.opacity(0.5), radius: 2); Text("Top Buddy: \(controller.topPerson)").font(.caption).bold().foregroundColor(.primary.opacity(0.7)) }
                        .padding(.horizontal, 12).padding(.vertical, 6).background(Material.thinMaterial).clipShape(Capsule()).shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2).padding(.top, 5)
                    }
                }.padding(.top, 20)
                
                Spacer()
                
                // Big Button
                ZStack {
                    ForEach(0..<3) { i in Circle().stroke(Color.orange.opacity(0.3), lineWidth: 1).frame(width: 250 + CGFloat(i*30), height: 250 + CGFloat(i*30)).scaleEffect(isBreathing ? 1.05 : 1.0).opacity(isBreathing ? 0.5 : 0.2).animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(i)*0.2), value: isBreathing) }
                    Button(action: { showLogSheet = true }) {
                        ZStack {
                            Circle().fill(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)).frame(width: 200, height: 200).shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)
                            VStack(spacing: 10) {
                                Image("AppLogo").resizable().scaledToFit().frame(width: 110, height: 110).shadow(radius: 5)
                                Text("TAP TO LOG").font(.caption).bold().foregroundColor(.white)
                            }
                        }
                    }
                }.padding(.vertical, 30).onAppear { isBreathing = true }
                
                Spacer()
                
                // Bottom Cards
                HStack(spacing: 15) {
                    StatBlock(title: "TODAY", value: "\(controller.dailyCount)", icon: "sun.max.fill", gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    StatBlock(title: "AWARDS", value: "\(controller.badges.filter { $0.isUnlocked }.count)", icon: "trophy.fill", gradient: LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                    StatBlock(title: "LAST SMILE", value: controller.lastLaughTime, icon: "clock.fill", gradient: LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing), isTextSmall: true)
                }.padding(.horizontal, 20).padding(.bottom, 30)
            }
        }.sheet(isPresented: $showLogSheet) { AddLaughSheet(controller: controller, laughToEdit: nil).presentationDetents([.fraction(0.65)]) }
    }
}

struct StatBlock: View {
    let title: String; let value: String; let icon: String; let gradient: LinearGradient; var isTextSmall: Bool = false
    var body: some View {
        ZStack {
            gradient
            VStack { HStack { Circle().fill(Color.white.opacity(0.2)).frame(width: 50, height: 50).offset(x: -20, y: -20); Spacer() }; Spacer() }.clipShape(RoundedRectangle(cornerRadius: 20))
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2).foregroundColor(.white.opacity(0.8)).frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text(value).font(isTextSmall ? .system(size: 14, weight: .bold) : .system(size: 28, weight: .heavy)).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1).minimumScaleFactor(0.5)
                Text(title).font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(.white.opacity(0.7)).frame(maxWidth: .infinity, alignment: .leading)
            }.padding(12)
        }.frame(height: 100).cornerRadius(20).shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 2. LOG/EDIT SHEET
struct AddLaughSheet: View {
    @ObservedObject var controller: LaughController; @Environment(\.dismiss) var dismiss; var laughToEdit: LaughEntry?
    @State private var selectedMood = "😄"; @State private var person = ""; @State private var note = ""; let moods = ["😄", "🤣", "🥹", "💀", "🙂"]
    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
            Text(laughToEdit == nil ? "How was the laugh?" : "Edit Laugh").font(.headline)
            HStack(spacing: 15) { ForEach(moods, id: \.self) { mood in Text(mood).font(.system(size: 45)).scaleEffect(selectedMood == mood ? 1.2 : 1.0).opacity(selectedMood == mood ? 1.0 : 0.5).animation(.spring(), value: selectedMood).onTapGesture { selectedMood = mood; SoundManager.shared.playClickSound() } } }.padding(.vertical, 5); Divider()
            VStack(alignment: .leading) { HStack { Text("Who with?").font(.caption).bold().foregroundColor(.gray); Spacer(); if controller.people.isEmpty { Text("Add people in Settings").font(.caption).foregroundColor(.red) } }; ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(controller.people, id: \.self) { p in Text(p).font(.subheadline).bold().padding(.horizontal, 16).padding(.vertical, 8).background(person == p ? Color.orange : Color.gray.opacity(0.1)).foregroundColor(person == p ? .white : .primary).cornerRadius(20).onTapGesture { person = p } } } } }.padding(.horizontal)
            VStack(alignment: .leading, spacing: 5) { Text("Add a note (optional)").font(.caption).bold().foregroundColor(.gray); TextField("E.g. Funny joke at lunch...", text: $note).padding().background(Color.gray.opacity(0.1)).cornerRadius(12) }.padding(.horizontal)
            Spacer()
            Button(action: {
                if let existing = laughToEdit { controller.updateLaugh(existing, mood: selectedMood, person: person.isEmpty ? nil : person); existing.note = note.isEmpty ? nil : note; try? controller.modelContext.save(); controller.refreshAll() }
                else { controller.logLaugh(mood: selectedMood, person: person.isEmpty ? nil : person, location: nil, note: note.isEmpty ? nil : note) }
                SoundManager.shared.playSmileSound(); dismiss()
            }) { HStack { Text(laughToEdit == nil ? "Save & Smile" : "Update Laugh"); Image(systemName: laughToEdit == nil ? "face.smiling.inverse" : "checkmark") }.bold().font(.title3).frame(maxWidth: .infinity).padding().background(Color.orange).foregroundColor(.white).cornerRadius(15).shadow(radius: 5) }.padding()
        }.onAppear { if let existing = laughToEdit { selectedMood = existing.mood; person = existing.person ?? ""; note = existing.note ?? "" } }
    }
}

// MARK: - 3. JOURNAL VIEW
struct JournalView: View {
    @ObservedObject var controller: LaughController
    @State private var viewMode = 0
    @State private var selectedDate: Date = Date()
    @State private var laughToEdit: LaughEntry?
    @Query(sort: \LaughEntry.timestamp, order: .reverse) var laughs: [LaughEntry]
    
    // Grid Configuration: 2 Columns
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("View", selection: $viewMode) {
                        Text("List").tag(0)
                        Text("Calendar").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(Color(uiColor: .systemGroupedBackground))
                    
                    if viewMode == 0 {
                        // --- GRID VIEW (New "List" Mode) ---
                        if laughs.isEmpty {
                            ContentUnavailableView("No laughs yet", systemImage: "face.dashed", description: Text("Start logging your daily joy!"))
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(laughs) { laugh in
                                        JournalCard(laugh: laugh)
                                            .onTapGesture { laughToEdit = laugh }
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    controller.deleteLaugh(laugh)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                        }
                    } else {
                        // --- CALENDAR VIEW ---
                        ScrollView {
                            VStack(spacing: 15) {
                                CalendarView(controller: controller, selectedDate: $selectedDate)
                                    .padding(.horizontal)
                                    .padding(.top)
                                
                                Divider().padding(.horizontal)
                                
                                let filteredLaughs = laughs.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
                                
                                HStack {
                                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if !filteredLaughs.isEmpty {
                                        Text("\(filteredLaughs.count) Laughs")
                                            .font(.caption).bold()
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(8)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .padding(.horizontal)
                                
                                if filteredLaughs.isEmpty {
                                    ContentUnavailableView(
                                        "No laughs on this day",
                                        systemImage: "calendar.badge.exclamationmark",
                                        description: Text("No entries found for this date.")
                                    )
                                    .padding(.top, 20)
                                } else {
                                    ForEach(filteredLaughs) { laugh in
                                        LaughRow(laugh: laugh) // Keeping row style for list under calendar
                                            .onTapGesture { laughToEdit = laugh }
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Laugh Journal")
            .sheet(item: $laughToEdit) { laugh in
                AddLaughSheet(controller: controller, laughToEdit: laugh)
                    .presentationDetents([.fraction(0.65)])
            }
        }
    }
}

// NEW: JOURNAL CARD (Achievement Style)
struct JournalCard: View {
    let laugh: LaughEntry
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 12) {
                // Mood Icon (Big)
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Text(laugh.mood)
                        .font(.system(size: 30))
                }
                
                // Info
                VStack(spacing: 4) {
                    Text(laugh.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text(laugh.person ?? "Solo Laugh")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    if let n = laugh.note, !n.isEmpty {
                        Text(n)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: 25)
                    } else {
                        Spacer().frame(height: 25)
                    }
                }
            }
            .padding(12)
        }
        .aspectRatio(0.85, contentMode: .fit)
    }
}

// CALENDAR LIST ROW
struct LaughRow: View {
    let laugh: LaughEntry
    var body: some View {
        HStack(spacing: 16) {
            Text(laugh.mood).font(.system(size: 34)).frame(width: 55, height: 55).background(Color.orange.opacity(0.1)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(laugh.timestamp.formatted(date: .omitted, time: .shortened)).font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                    if let loc = laugh.location, !loc.isEmpty { Text("•").font(.caption).foregroundColor(.gray); Text(loc).font(.caption).foregroundColor(.gray) }
                }
                if let p = laugh.person, !p.isEmpty { Text(p).font(.body).fontWeight(.semibold).foregroundColor(.primary) } else { Text("Solo Laugh").font(.body).italic().foregroundColor(.secondary) }
                if let n = laugh.note, !n.isEmpty { Text(n).font(.subheadline).foregroundColor(.gray).lineLimit(1) }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray.opacity(0.5))
        }.padding(14).background(Color(uiColor: .secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct CalendarView: View {
    @ObservedObject var controller: LaughController; @Binding var selectedDate: Date; let columns = Array(repeating: GridItem(.flexible()), count: 7); let days = ["S", "M", "T", "W", "T", "F", "S"]
    func daysInMonth() -> [Date?] { let c = Calendar.current; guard let interval = c.dateInterval(of: .month, for: selectedDate) else { return [] }; let start = interval.start; let total = c.range(of: .day, in: .month, for: selectedDate)!.count; let dayOne = c.component(.weekday, from: start); var arr: [Date?] = Array(repeating: nil, count: dayOne - 1); for i in 0..<total { arr.append(c.date(byAdding: .day, value: i, to: start)) }; return arr }
    var body: some View { VStack { HStack { Button(action: { moveMonth(by: -1) }) { Image(systemName: "chevron.left") }; Spacer(); Text(selectedDate.formatted(.dateTime.month().year())).font(.title3).bold(); Spacer(); Button(action: { moveMonth(by: 1) }) { Image(systemName: "chevron.right") } }.padding(.bottom, 10); HStack { ForEach(days, id: \.self) { d in Text(d).font(.caption2).bold().foregroundColor(.gray).frame(maxWidth: .infinity) } }; LazyVGrid(columns: columns, spacing: 10) { ForEach(0..<daysInMonth().count, id: \.self) { i in if let date = daysInMonth()[i] { let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate); let count = controller.laughsByDate[Calendar.current.startOfDay(for: date)] ?? 0; Button(action: { withAnimation { selectedDate = date } }) { VStack(spacing: 4) { Text("\(Calendar.current.component(.day, from: date))").font(.caption).fontWeight(isSelected ? .bold : .regular).foregroundColor(isSelected ? .white : .primary); Circle().fill(isSelected ? .white : (count > 0 ? Color.orange : Color.clear)).frame(width: 5, height: 5) }.frame(height: 45).frame(maxWidth: .infinity).background(isSelected ? Color.blue : (count > 0 ? Color.orange.opacity(0.15) : Color.clear)).cornerRadius(10) } } else { Text("").frame(height: 45) } } } }.padding().background(Color.white).cornerRadius(16).shadow(color: .black.opacity(0.05), radius: 5) }
    func moveMonth(by value: Int) { if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) { selectedDate = newDate } }
}

// MARK: - 4. STATS VIEW
struct StatsView: View {
    @ObservedObject var controller: LaughController
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Period", selection: $controller.selectedTimeRange) { ForEach(TimeRange.allCases) { range in Text(range.rawValue).tag(range) } }.pickerStyle(.segmented).padding(.horizontal).padding(.top, 20).onChange(of: controller.selectedTimeRange) { _ in controller.updateInsights() }
                    if controller.selectedTimeRange == .custom { VStack { DatePicker("Start", selection: $controller.customStartDate, displayedComponents: .date); DatePicker("End", selection: $controller.customEndDate, displayedComponents: .date) }.padding().background(Color.white).cornerRadius(12).padding(.horizontal).onChange(of: controller.customStartDate) { _ in controller.updateInsights() }.onChange(of: controller.customEndDate) { _ in controller.updateInsights() } }
                    VStack(alignment: .leading) {
                        Text("Trend").font(.headline).padding(.bottom, 5)
                        Chart { ForEach(controller.insightsChartData.sorted(by: { $0.key < $1.key }), id: \.key) { date, count in BarMark(x: .value("Time", date, unit: controller.insightsChartUnit), y: .value("Laughs", count)).foregroundStyle(LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top)).cornerRadius(4) } }.frame(height: 200)
                    }.padding().background(Color.white).cornerRadius(20).shadow(color: .black.opacity(0.05), radius: 8).padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) { StatBox(title: "Laughs in Period", value: "\(controller.insightsTotal)", icon: "infinity", color: .blue); StatBox(title: "Current Streak", value: "\(controller.weeklyStreak) Days", icon: "flame.fill", color: .orange) }.padding(.horizontal)
                    HStack(spacing: 15) { ZStack { Circle().fill(Color.pink.opacity(0.1)).frame(width: 50, height: 50); Image(systemName: "person.2.fill").foregroundColor(.pink).font(.title2) }; VStack(alignment: .leading) { Text("Top Laugh Buddy (in Period)").font(.caption).foregroundColor(.gray).bold(); Text(controller.insightsTopPerson).font(.title3).bold() }; Spacer() }.padding().background(Color.white).cornerRadius(20).shadow(color: .black.opacity(0.05), radius: 5).padding(.horizontal)
                    Spacer(minLength: 50)
                }
            }.background(Color(uiColor: .systemGroupedBackground)).navigationTitle("Insights").onAppear { controller.updateInsights() }
        }
    }
}

// *** ADDED BACK MISSING STRUCT ***
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title2).bold()
                Text(title).font(.caption).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 5. ACHIEVEMENTS VIEW
struct AchievementsView: View {
    @ObservedObject var controller: LaughController
    let columns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        HStack { Text("Your Trophy Case").font(.headline).foregroundColor(.gray); Spacer(); Text("\(controller.badges.filter { $0.isUnlocked }.count) / \(controller.badges.count)").font(.headline).bold().foregroundColor(.orange) }
                        GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(Color.gray.opacity(0.2)).frame(height: 10); Capsule().fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)).frame(width: geo.size.width * (Double(controller.badges.filter { $0.isUnlocked }.count) / Double(controller.badges.count)), height: 10) } }.frame(height: 10)
                    }.padding().background(Color.white).cornerRadius(16).shadow(color: .black.opacity(0.05), radius: 5).padding(.horizontal)
                    LazyVGrid(columns: columns, spacing: 15) { ForEach(controller.badges) { badge in AchievementCard(badge: badge) } }.padding(.horizontal).padding(.bottom, 20)
                }.padding(.top)
            }.navigationTitle("Achievements").background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

struct AchievementCard: View {
    let badge: Achievement
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Color(uiColor: .secondarySystemGroupedBackground)).shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            if badge.isUnlocked { RoundedRectangle(cornerRadius: 20).stroke(badge.color.opacity(0.3), lineWidth: 2) }
            VStack(spacing: 12) {
                ZStack { Circle().fill(badge.isUnlocked ? badge.color.opacity(0.1) : Color.gray.opacity(0.1)).frame(width: 60, height: 60); if badge.isUnlocked { Text(badge.icon).font(.system(size: 30)) } else { Image(systemName: "lock.fill").font(.system(size: 24)).foregroundColor(.gray.opacity(0.4)) } }
                VStack(spacing: 4) {
                    Text(badge.title).font(.footnote).fontWeight(.bold).multilineTextAlignment(.center).foregroundColor(badge.isUnlocked ? .primary : .gray).lineLimit(1)
                    if badge.isUnlocked { Text(badge.description).font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center).lineLimit(2).frame(height: 25) } else { Text("Locked").font(.caption2).foregroundColor(.gray.opacity(0.5)).frame(height: 25) }
                }
            }.padding(12)
        }.aspectRatio(0.85, contentMode: .fit).opacity(badge.isUnlocked ? 1.0 : 0.8)
    }
}

// MARK: - 6. SETTINGS VIEW
struct SettingsView: View {
    @ObservedObject var controller: LaughController; @State private var newPersonName: String = ""; @State private var isAddingPerson = false
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Preferences")) { Toggle(isOn: $controller.isNotificationsEnabled) { Label("Enable Notifications", systemImage: "bell.fill") }; Toggle(isOn: $controller.isSoundEnabled) { Label("Play Sounds", systemImage: "speaker.wave.2.fill") } }
                Section(header: Text("Manage People")) {
                    ForEach(controller.people.indices, id: \.self) { index in HStack { Image(systemName: "person.fill").foregroundColor(.gray); TextField("Name", text: Binding(get: { controller.people[index] }, set: { controller.people[index] = $0; controller.savePeople() })) } }.onDelete { controller.deletePerson(at: $0) }.onMove { controller.movePerson(from: $0, to: $1) }
                    Button(action: { isAddingPerson = true }) { Label("Add Person", systemImage: "plus.circle.fill").foregroundColor(.blue) }
                }
                Section(header: Text("Data Management")) { ShareLink(item: controller.generateCSV()) { Label("Export Journal to CSV", systemImage: "arrow.down.doc") } }
                Section(header: Text("About")) { HStack { Text("Version"); Spacer(); Text("1.0.0").foregroundColor(.secondary) }; Text("LaughMeter: Daily quotes, better stats, and pure joy.").font(.caption).foregroundColor(.secondary) }
            }
            .navigationTitle("Settings")
            .alert("Add New Person", isPresented: $isAddingPerson) { TextField("Name", text: $newPersonName); Button("Cancel", role: .cancel) { newPersonName = "" }; Button("Add") { controller.addPerson(newPersonName); newPersonName = "" } } message: { Text("Enter the name of a friend, group, or context you laugh with.") }
        }
    }
}
