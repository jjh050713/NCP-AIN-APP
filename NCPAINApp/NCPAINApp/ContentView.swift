import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: QuestionStore

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }

            StudyView()
                .tabItem {
                    Label("암기", systemImage: "rectangle.stack.fill")
                }

            ImportView()
                .tabItem {
                    Label("덤프", systemImage: "square.and.arrow.down")
                }
        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
        .environmentObject(QuestionStore())
}
