import SwiftUI
import SwiftData

@main
struct SkullCountApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Player.self,
                Game.self,
                GameParticipant.self,
                Round.self,
                RoundEntry.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Erreur d'initialisation de SwiftData: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeDashboardView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
