import Foundation
import SwiftUI

struct ExamScore: Codable, Equatable {
    let correct: Int
    let total: Int
    let percent: Double
}

struct MockExamState: Codable, Equatable {
    var started = false
    var finished = false
    var currentIndex = 0
    var answers: [String: [Int]] = [:]
    var score: ExamScore?
}

@MainActor
final class MockExamStore: ObservableObject {
    @Published private(set) var questions: [Question] = []
    @Published private(set) var isLoading = true
    @Published private(set) var state = MockExamState()

    @AppStorage("mockExamStateData") private var stateData = Data()

    private var hasLoaded = false
    private var loadTask: Task<Void, Never>?

    init() {
        state = Self.decodeState(stateData)
    }

    /// Loads the 120-question exam bank the first time the 모의고사 tab is
    /// actually opened, rather than eagerly at app launch alongside the main
    /// study question bank. Cheap to call repeatedly; only loads once.
    func loadIfNeeded() {
        guard !hasLoaded, loadTask == nil else { return }
        isLoading = true
        loadTask = Task {
            let loaded = await Task.detached(priority: .userInitiated) {
                Self.loadFromBundle()
            }.value
            questions = loaded
            isLoading = false
            hasLoaded = true
            loadTask = nil
        }
    }

    var currentIndex: Int {
        min(max(state.currentIndex, 0), max(questions.count - 1, 0))
    }

    var currentQuestion: Question? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

    var answeredCount: Int {
        state.answers.values.filter { !$0.isEmpty }.count
    }

    func selectedIndices(for question: Question) -> Set<Int> {
        Set(state.answers[question.id] ?? [])
    }

    func start() {
        state.started = true
        persist()
    }

    func toggleChoice(_ question: Question, index: Int) {
        var selected = selectedIndices(for: question)
        if question.isMultiSelect {
            if selected.contains(index) {
                selected.remove(index)
            } else {
                selected.insert(index)
            }
        } else {
            selected = [index]
        }
        state.answers[question.id] = Array(selected)
        persist()
    }

    func goNext() {
        guard state.currentIndex < questions.count - 1 else { return }
        state.currentIndex += 1
        persist()
    }

    func goPrevious() {
        guard state.currentIndex > 0 else { return }
        state.currentIndex -= 1
        persist()
    }

    func isCorrect(_ question: Question) -> Bool {
        let given = selectedIndices(for: question)
        let answer = Set(question.correctIndices)
        return given == answer
    }

    var unansweredCount: Int {
        questions.filter { (state.answers[$0.id] ?? []).isEmpty }.count
    }

    func submit() {
        let correct = questions.filter { isCorrect($0) }.count
        let total = questions.count
        let percent = total > 0 ? (Double(correct) / Double(total) * 1000).rounded() / 10 : 0
        state.finished = true
        state.score = ExamScore(correct: correct, total: total, percent: percent)
        persist()
    }

    func wrongQuestions() -> [Question] {
        questions.filter { !isCorrect($0) }
    }

    func retry() {
        state = MockExamState(started: true)
        persist()
    }

    // MARK: - Private

    private func persist() {
        stateData = (try? JSONEncoder().encode(state)) ?? Data()
        objectWillChange.send()
    }

    private nonisolated static func decodeState(_ data: Data) -> MockExamState {
        (try? JSONDecoder().decode(MockExamState.self, from: data)) ?? MockExamState()
    }

    private nonisolated static func loadFromBundle() -> [Question] {
        guard let url = Bundle.main.url(forResource: "exam120", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bank = try? JSONDecoder().decode(QuestionBank.self, from: data) else {
            return []
        }
        return bank.questions
    }
}
