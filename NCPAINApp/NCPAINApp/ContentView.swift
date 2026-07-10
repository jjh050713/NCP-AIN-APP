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

            MockExamView()
                .tabItem {
                    Label("모의고사", systemImage: "doc.text.fill")
                }

            ImportView()
                .tabItem {
                    Label("덤프", systemImage: "square.and.arrow.down")
                }
        }
        .tint(.green)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    ContentView()
        .environmentObject(QuestionStore())
        .environmentObject(MockExamStore())
}
