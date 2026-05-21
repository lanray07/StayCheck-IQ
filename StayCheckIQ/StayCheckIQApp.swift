import SwiftData
import SwiftUI

@main
@MainActor
struct StayCheckIQApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var services = AppServices()

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            RentalProperty.self,
            TurnoverCheck.self,
            TurnoverChecklistItem.self,
            RoomPhoto.self,
            StayIssue.self,
            InventoryItem.self,
            TurnoverReport.self,
            SubscriptionState.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create StayCheck IQ model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .modelContainer(modelContainer)
                .environmentObject(services)
                .tint(.stayTeal)
                .task {
                    services.subscriptionService.startTransactionListener()
                    await services.subscriptionService.loadProducts()
                    _ = await services.notificationService.requestAuthorization()
                }
        }
    }
}
