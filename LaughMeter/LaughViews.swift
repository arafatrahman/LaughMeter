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
            AchievementsView(controller: controller).tabItem { Label("Awards", systemImage: "trophy.fill") }
            SettingsView(controller: controller).tabItem { Label("Settings", systemImage: "gear") }
        }
        .accentColor(.orange)
    }
}

// MARK: - 1. HOME VIEW (Redesigned + Quotes)
struct HomeView: View {
    @ObservedObject var controller: LaughController
    @State private var showLogSheet = false
    @State private var isBreathing = false
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2), Color.pink.opacity(0.1)],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) { animateGradient.toggle() }
            }
            
            VStack(spacing: 0) {
                // Header & Quote
                VStack(spacing: 10) {
                    Text("Daily Dose of Joy")
                        .font(.caption).bold().textCase(.uppercase).tracking(2).foregroundColor(.secondary)
                    
                    Text("\"\(QuoteManager.getDailyQuote())\"")
                        .font(.body)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Main Interaction
                ZStack {
                    // Ripples
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            .frame(width: 250 + CGFloat(i*30), height: 250 + CGFloat(i*30))
                            .scaleEffect(isBreathing ? 1.05 : 1.0)
                            .opacity(isBreathing ? 0.5 : 0.2)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(i)*0.2), value: isBreathing)
                    }
                    
                    Button(action: {
                        SoundManager.shared.playClickSound()
                        showLogSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                                .frame(width: 200, height: 200)
                                .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            VStack(spacing: 5) {
                                Text("😂")
                                    .font(.system(size: 80))
                                    .shadow(radius: 5)
                                Text("TAP TO LOG")
                                    .font(.caption).bold().foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.vertical, 30)
                .onAppear { isBreathing = true }
                
                Spacer()
                
                // Info Grid
                HStack(spacing: 15) {
                    InfoCard(title: "Today", value: "\(controller.dailyCount)", icon: "checkmark.circle.fill", color: .blue)
                    InfoCard(title: "Streak", value: "\(controller.weeklyStreak)", icon: "flame.fill", color: .orange)
                    InfoCard(title: "Last Laugh", value: controller.lastLaughTime, icon: "clock.fill", color: .purple)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showLogSheet) {
            AddLaughSheet(controller: controller, laughToEdit: nil)
                .presentationDetents([.fraction(0.55)])
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.7))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5)
    }
}

// MARK: - 2. LOG/EDIT SHEET
struct AddLaughSheet: View {
    @ObservedObject var controller: LaughController
    @Environment(\.dismiss) var dismiss
    
    var laughToEdit: LaughEntry? // If not nil, we are editing
    
    @State private var selectedMood = "😂"
    @State private var person = ""
    
    let moods = ["😂", "🤣", "🥹", "💀", "🙂"]
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
            
            Text(laughToEdit == nil ? "How was the laugh?" : "Edit Laugh").font(.headline)
            
            HStack(spacing: 15) {
                ForEach(moods, id: \.self) { mood in
                    Text(mood)
                        .font(.system(size: 45))
                        .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                        .opacity(selectedMood == mood ? 1.0 : 0.5)
                        .animation(.spring(), value: selectedMood)
                        .onTapGesture {
                            selectedMood = mood
                            SoundManager.shared.playClickSound()
                        }
                }
            }
            .padding(.vertical, 10)
            
            Divider()
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Who with?").font(.caption).bold().foregroundColor(.gray)
                    Spacer()
                    if controller.people.isEmpty {
                        Text("Add people in Settings").font(.caption).foregroundColor(.red)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(controller.people, id: \.self) { p in
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
                if let existing = laughToEdit {
                    controller.updateLaugh(existing, mood: selectedMood, person: person.isEmpty ? nil : person)
                } else {
                    controller.logLaugh(mood: selectedMood, person: person.isEmpty ? nil : person, location: nil, note: nil)
                }
                dismiss()
            }) {
                HStack {
                    Text(laughToEdit == nil ? "Save & Smile" : "Update Laugh")
                    Image(systemName: laughToEdit == nil ? "face.smiling.inverse" : "checkmark")
                }
                .bold().font(.title3).frame(maxWidth: .infinity).padding()
                .background(Color.orange).foregroundColor(.white).cornerRadius(15).shadow(radius: 5)
            }.padding()
        }
        .onAppear {
            if let existing = laughToEdit {
                selectedMood = existing.mood
                person = existing.person ?? ""
            }
        }
    }
}

// MARK: - 3. JOURNAL VIEW (Calendar with Edit/Delete)
struct JournalView: View {
    @ObservedObject var controller: LaughController
    @State private var viewMode = 0
    @State private var selectedDate: Date = Date()
    @State private var laughToEdit: LaughEntry? // For editing sheet
    @Query(sort: \LaughEntry.timestamp, order: .reverse) var laughs: [LaughEntry]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $viewMode) {
                    Text("List").tag(0)
                    Text("Calendar").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if viewMode == 0 {
                    // --- LIST MODE ---
                    List {
                        ForEach(laughs) { laugh in
                            LaughRow(laugh: laugh)
                                .contentShape(Rectangle())
                                .onTapGesture { laughToEdit = laugh } // Tap to edit in list too
                        }
                        .onDelete { idx in idx.forEach { controller.deleteLaugh(laughs[$0]) } }
                    }
                    .listStyle(.plain)
                    
                } else {
                    // --- CALENDAR MODE ---
                    VStack(spacing: 0) {
                        CalendarView(controller: controller, selectedDate: $selectedDate)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        
                        Divider()
                        
                        let filteredLaughs = laughs.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
                        
                        HStack {
                            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline).foregroundColor(.gray)
                            Spacer()
                            if !filteredLaughs.isEmpty {
                                Text("\(filteredLaughs.count) Laughs").font(.caption).bold()
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        
                        if filteredLaughs.isEmpty {
                            ContentUnavailableView("No laughs logged", systemImage: "face.dashed", description: Text("Tap '+' to log a laugh for today."))
                                .padding(.top, 40)
                            Spacer()
                        } else {
                            List {
                                ForEach(filteredLaughs) { laugh in
                                    LaughRow(laugh: laugh)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                controller.deleteLaugh(laugh)
                                            } label: { Label("Delete", systemImage: "trash") }
                                            
                                            Button {
                                                laughToEdit = laugh
                                            } label: { Label("Edit", systemImage: "pencil") }
                                                .tint(.blue)
                                        }
                                        .onTapGesture { laughToEdit = laugh } // Easy tap to edit
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Laugh Journal")
            .background(Color(uiColor: .systemGroupedBackground))
            .sheet(item: $laughToEdit) { laugh in
                AddLaughSheet(controller: controller, laughToEdit: laugh)
                    .presentationDetents([.fraction(0.55)])
            }
        }
    }
}

// --- Helper Components for Journal ---
struct LaughRow: View {
    let laugh: LaughEntry
    
    var body: some View {
        HStack(spacing: 15) {
            Text(laugh.mood)
                .font(.system(size: 32))
                .frame(width: 50, height: 50)
                .background(Color.orange.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(laugh.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption).bold().foregroundColor(.gray)
                
                if let p = laugh.person, !p.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill").font(.caption2)
                        Text(p).font(.subheadline).bold()
                    }.foregroundColor(.blue)
                } else {
                    Text("Solo Laugh").font(.subheadline).italic().foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

struct CalendarView: View {
    @ObservedObject var controller: LaughController
    @Binding var selectedDate: Date
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    let days = ["S", "M", "T", "W", "T", "F", "S"]
    
    func daysInMonth() -> [Date?] {
        let c = Calendar.current
        guard let interval = c.dateInterval(of: .month, for: selectedDate) else { return [] }
        let start = interval.start
        let dayOne = c.component(.weekday, from: start)
        let total = c.range(of: .day, in: .month, for: selectedDate)!.count
        
        var arr: [Date?] = Array(repeating: nil, count: dayOne - 1)
        for i in 0..<total {
            arr.append(c.date(byAdding: .day, value: i, to: start))
        }
        return arr
    }
    
    var body: some View {
        VStack {
            // Month Navigation
            HStack {
                Button(action: { moveMonth(by: -1) }) { Image(systemName: "chevron.left") }
                Spacer()
                Text(selectedDate.formatted(.dateTime.month().year()))
                    .font(.title3).bold()
                Spacer()
                Button(action: { moveMonth(by: 1) }) { Image(systemName: "chevron.right") }
            }
            .padding(.bottom, 10)
            
            // Days Header
            HStack {
                ForEach(days, id: \.self) { d in
                    Text(d).font(.caption2).bold().foregroundColor(.gray).frame(maxWidth: .infinity)
                }
            }
            
            // Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<daysInMonth().count, id: \.self) { i in
                    if let date = daysInMonth()[i] {
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        let count = controller.laughsByDate[Calendar.current.startOfDay(for: date)] ?? 0
                        
                        Button(action: {
                            withAnimation { selectedDate = date }
                        }) {
                            VStack(spacing: 4) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.caption)
                                    .fontWeight(isSelected ? .bold : .regular)
                                    .foregroundColor(isSelected ? .white : .primary)
                                
                                if count > 0 {
                                    Circle()
                                        .fill(isSelected ? .white : Color.orange)
                                        .frame(width: 5, height: 5)
                                } else {
                                    Circle().fill(Color.clear).frame(width: 5, height: 5)
                                }
                            }
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 10).fill(Color.blue)
                                    } else if count > 0 {
                                        RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.15))
                                    }
                                }
                            )
                        }
                    } else {
                        Text("").frame(height: 45)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    func moveMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// MARK: - 4. STATS & SHARE (Unchanged)
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

// MARK: - 5. SETTINGS (Manage People + Data)
struct SettingsView: View {
    @ObservedObject var controller: LaughController
    @State private var newPersonName: String = ""
    @State private var isAddingPerson = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Custom People
                Section(header: Text("Manage People")) {
                    ForEach(controller.people, id: \.self) { person in
                        Label(person, systemImage: "person.fill")
                    }
                    .onDelete { idx in controller.deletePerson(at: idx) }
                    .onMove { src, dst in controller.movePerson(from: src, to: dst) }
                    
                    Button(action: { isAddingPerson = true }) {
                        Label("Add Person", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                // Section 2: Data
                Section(header: Text("Data Management")) {
                    ShareLink(item: controller.generateCSV()) {
                        Label("Export Journal to CSV", systemImage: "arrow.down.doc")
                    }
                }
                
                // Section 3: Info
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.3.0")
                            .foregroundColor(.secondary)
                    }
                    Text("LaughMeter: Daily quotes, better stats, and pure joy.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                EditButton()
            }
            .alert("Add New Person", isPresented: $isAddingPerson) {
                TextField("Name", text: $newPersonName)
                Button("Cancel", role: .cancel) { newPersonName = "" }
                Button("Add") {
                    controller.addPerson(newPersonName)
                    newPersonName = ""
                }
            } message: {
                Text("Enter the name of a friend, group, or context you laugh with.")
            }
        }
    }
}
