import SwiftUI

@main
struct NCPAINAppApp: App {
    @StateObject private var store = QuestionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .tint(.green)
        }
    }
}
