import SwiftUI

@main
struct NCPAINAppApp: App {
    @StateObject private var store = QuestionStore()
    @StateObject private var examStore = MockExamStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(examStore)
                .tint(.green)
        }
    }
}
