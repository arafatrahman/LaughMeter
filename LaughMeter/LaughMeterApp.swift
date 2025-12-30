import SwiftUI
import SwiftData

@main
struct LaughMeterApp: App {
    let container: ModelContainer
    init() {
        do {
            let schema = Schema([LaughEntry.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch { fatalError("Could not create ModelContainer: \(error)") }
    }
    var body: some Scene {
        WindowGroup { MainView(context: container.mainContext) }.modelContainer(container)
    }
}
