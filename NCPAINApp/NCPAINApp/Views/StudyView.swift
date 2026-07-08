import SwiftUI

struct StudyView: View {
    @EnvironmentObject private var store: QuestionStore

    var initialCategory: QuestionCategory? = nil

    @State private var selectedCategory: QuestionCategory?
    @State private var showBookmarkedOnly = false
    @State private var showDumpOnly = false
    @State private var shuffleEnabled = false
    @State private var currentIndex = 0
    @State private var sessionQuestions: [Question] = []
    @State private var roundMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                if let roundMessage {
                    Text(roundMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.12))
                }

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
            .onChange(of: showDumpOnly) { _, _ in reloadSession() }
            .onChange(of: shuffleEnabled) { _, _ in reloadSession() }
            .onChange(of: store.questions) { _, _ in reloadSession() }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "전체", isSelected: selectedCategory == nil && !showBookmarkedOnly && !showDumpOnly) {
                    selectedCategory = nil
                    showBookmarkedOnly = false
                    showDumpOnly = false
                }

                FilterChip(title: "기출", isSelected: showDumpOnly) {
                    showDumpOnly = true
                    showBookmarkedOnly = false
                    selectedCategory = nil
                }

                FilterChip(title: "북마크", isSelected: showBookmarkedOnly) {
                    showBookmarkedOnly = true
                    showDumpOnly = false
                    if showBookmarkedOnly { selectedCategory = nil }
                }

                FilterChip(title: shuffleEnabled ? "셔플 ON" : "셔플 OFF", isSelected: shuffleEnabled) {
                    shuffleEnabled.toggle()
                }

                ForEach(QuestionCategory.allCases) { category in
                    FilterChip(title: shortName(category), isSelected: selectedCategory == category) {
                        showBookmarkedOnly = false
                        showDumpOnly = false
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
        Group {
            if !sessionQuestions.isEmpty {
                QuestionCardView(
                    question: sessionQuestions[currentIndex],
                    index: currentIndex + 1,
                    total: sessionQuestions.count,
                    isBookmarked: store.isBookmarked(sessionQuestions[currentIndex]),
                    onToggleBookmark: { store.toggleBookmark(sessionQuestions[currentIndex]) }
                )
                .padding(.horizontal)
                .id(sessionQuestions[currentIndex].id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            if value.translation.width < -50 {
                                goToNext()
                            } else if value.translation.width > 50 {
                                goToPrevious()
                            }
                        }
                )
            }
        }
        .frame(maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
        .sensoryFeedback(.selection, trigger: currentIndex)
    }

    private var navigationBar: some View {
        HStack {
            Button(action: goToPrevious) {
                Label("이전", systemImage: "chevron.left")
            }
            .disabled(sessionQuestions.isEmpty)

            Spacer()

            Text("\(currentIndex + 1) / \(sessionQuestions.count)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: goToNext) {
                Label("다음", systemImage: "chevron.right")
            }
            .disabled(sessionQuestions.isEmpty)
        }
        .padding()
        .background(.bar)
        .safeAreaPadding(.bottom, 4)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("문제 없음", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("필터를 변경하거나 덤프 파일을 가져오세요.")
        }
        .frame(maxHeight: .infinity)
    }

    private func goToNext() {
        guard !sessionQuestions.isEmpty else { return }

        store.reveal(sessionQuestions[currentIndex])
        HapticManager.lightTap()
        withAnimation(.easeInOut(duration: 0.25)) {
            if currentIndex >= sessionQuestions.count - 1 {
                currentIndex = 0
                showRoundCompleteMessage()
                HapticManager.success()
            } else {
                currentIndex += 1
            }
        }
    }

    private func goToPrevious() {
        guard !sessionQuestions.isEmpty else { return }

        HapticManager.lightTap()
        withAnimation(.easeInOut(duration: 0.25)) {
            if currentIndex <= 0 {
                currentIndex = sessionQuestions.count - 1
            } else {
                currentIndex -= 1
            }
        }
    }

    private func showRoundCompleteMessage() {
        roundMessage = "한 바퀴 완료! 처음부터 다시 시작합니다."
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                roundMessage = nil
            }
        }
    }

    private func reloadSession() {
        var items: [Question]
        if showBookmarkedOnly {
            items = store.bookmarkedQuestions()
        } else if showDumpOnly {
            items = store.dumpQuestions()
        } else {
            items = store.questions(in: selectedCategory)
        }
        if shuffleEnabled {
            items.shuffle()
        }
        sessionQuestions = items
        currentIndex = min(currentIndex, max(0, items.count - 1))
        roundMessage = nil
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
