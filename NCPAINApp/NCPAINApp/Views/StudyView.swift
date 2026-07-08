import SwiftUI

struct StudyView: View {
    @EnvironmentObject private var store: QuestionStore

    var initialCategory: QuestionCategory? = nil

    @State private var selectedCategory: QuestionCategory?
    @State private var showBookmarkedOnly = false
    @State private var shuffleEnabled = false
    @State private var currentIndex = 0
    @State private var sessionQuestions: [Question] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                if sessionQuestions.isEmpty {
                    emptyState
                } else {
                    questionArea
                    navigationBar
                }
            }
            .navigationTitle("암기 학습")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("진행률 초기화", role: .destructive) {
                            store.resetProgress()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = initialCategory
                }
                reloadSession()
            }
            .onChange(of: selectedCategory) { _, _ in reloadSession() }
            .onChange(of: showBookmarkedOnly) { _, _ in reloadSession() }
            .onChange(of: shuffleEnabled) { _, _ in reloadSession() }
            .onChange(of: store.questions) { _, _ in reloadSession() }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "전체", isSelected: selectedCategory == nil && !showBookmarkedOnly) {
                    selectedCategory = nil
                    showBookmarkedOnly = false
                }

                FilterChip(title: "북마크", isSelected: showBookmarkedOnly) {
                    showBookmarkedOnly.toggle()
                    if showBookmarkedOnly { selectedCategory = nil }
                }

                FilterChip(title: shuffleEnabled ? "셔플 ON" : "셔플 OFF", isSelected: shuffleEnabled) {
                    shuffleEnabled.toggle()
                }

                ForEach(QuestionCategory.allCases) { category in
                    FilterChip(title: shortName(category), isSelected: selectedCategory == category) {
                        showBookmarkedOnly = false
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }

    private var questionArea: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(sessionQuestions.enumerated()), id: \.element.id) { index, question in
                QuestionCardView(
                    question: question,
                    index: index + 1,
                    total: sessionQuestions.count,
                    isRevealed: store.isRevealed(question),
                    isBookmarked: store.isBookmarked(question),
                    onReveal: { store.reveal(question) },
                    onToggleBookmark: { store.toggleBookmark(question) }
                )
                .tag(index)
                .padding(.horizontal)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var navigationBar: some View {
        HStack {
            Button {
                withAnimation { currentIndex = max(0, currentIndex - 1) }
            } label: {
                Label("이전", systemImage: "chevron.left")
            }
            .disabled(currentIndex == 0)

            Spacer()

            Text("\(currentIndex + 1) / \(sessionQuestions.count)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                withAnimation { currentIndex = min(sessionQuestions.count - 1, currentIndex + 1) }
            } label: {
                Label("다음", systemImage: "chevron.right")
            }
            .disabled(currentIndex >= sessionQuestions.count - 1)
        }
        .padding()
        .background(.bar)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("문제 없음", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("필터를 변경하거나 덤프 파일을 가져오세요.")
        }
        .frame(maxHeight: .infinity)
    }

    private func reloadSession() {
        var items: [Question]
        if showBookmarkedOnly {
            items = store.bookmarkedQuestions()
        } else {
            items = store.questions(in: selectedCategory)
        }
        if shuffleEnabled {
            items.shuffle()
        }
        sessionQuestions = items
        currentIndex = min(currentIndex, max(0, items.count - 1))
    }

    private func shortName(_ category: QuestionCategory) -> String {
        switch category {
        case .aiDataCenter: return "AI DC"
        case .spectrumNetworking: return "Spectrum"
        case .infinibandNetworking: return "IB"
        case .kubernetes: return "K8s"
        case .troubleshooting: return "Debug"
        case .automation: return "Auto"
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.green.opacity(0.2) : Color(.systemGray5))
                .foregroundStyle(isSelected ? .green : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StudyView()
        .environmentObject(QuestionStore())
}
