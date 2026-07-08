import Foundation
import SwiftUI

@MainActor
final class QuestionStore: ObservableObject {
    @Published private(set) var questions: [Question] = []
    @Published private(set) var isLoading = true
    @Published private(set) var loadError: String?

    @AppStorage("revealedQuestionIDs") private var revealedIDsData = Data()
    @AppStorage("bookmarkedQuestionIDs") private var bookmarkedIDsData = Data()

    private var revealedIDs: Set<String> {
        get { (try? JSONDecoder().decode(Set<String>.self, from: revealedIDsData)) ?? [] }
        set { revealedIDsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    private var bookmarkedIDs: Set<String> {
        get { (try? JSONDecoder().decode(Set<String>.self, from: bookmarkedIDsData)) ?? [] }
        set { bookmarkedIDsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init() {
        Task { await loadQuestions() }
    }

    func loadQuestions() async {
        isLoading = true
        loadError = nil

        var loaded: [Question] = []

        if let bundled = loadBundledQuestions() {
            loaded.append(contentsOf: bundled)
        }

        if let imported = loadImportedQuestions() {
            loaded.append(contentsOf: imported)
        }

        questions = deduplicated(loaded)
        isLoading = false

        if questions.isEmpty {
            loadError = "문제를 불러올 수 없습니다."
        }
    }

    func questions(in category: QuestionCategory?) -> [Question] {
        guard let category else { return questions }
        return questions.filter { $0.category == category }
    }

    func bookmarkedQuestions() -> [Question] {
        questions.filter { bookmarkedIDs.contains($0.id) }
    }

    func isRevealed(_ question: Question) -> Bool {
        revealedIDs.contains(question.id)
    }

    func isBookmarked(_ question: Question) -> Bool {
        bookmarkedIDs.contains(question.id)
    }

    func reveal(_ question: Question) {
        var ids = revealedIDs
        ids.insert(question.id)
        revealedIDs = ids
        objectWillChange.send()
    }

    func toggleBookmark(_ question: Question) {
        var ids = bookmarkedIDs
        if ids.contains(question.id) {
            ids.remove(question.id)
        } else {
            ids.insert(question.id)
        }
        bookmarkedIDs = ids
        objectWillChange.send()
    }

    func resetProgress() {
        revealedIDs = []
        objectWillChange.send()
    }

    func importDump(from url: URL) throws -> Int {
        let data = try Data(contentsOf: url)
        let bank = try JSONDecoder().decode(QuestionBank.self, from: data)
        let validated = bank.questions.filter { validate($0) }

        var existing = loadImportedQuestions() ?? []
        existing.append(contentsOf: validated.map { question in
            Question(
                id: question.id,
                category: question.category,
                question: question.question,
                choices: question.choices,
                correctIndex: question.correctIndex,
                source: .dump
            )
        })

        let encoded = try JSONEncoder().encode(deduplicated(existing))
        try encoded.write(to: importedQuestionsURL(), options: .atomic)

        Task { await loadQuestions() }
        return validated.count
    }

    func removeImportedQuestions() throws {
        let url = importedQuestionsURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        Task { await loadQuestions() }
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(revealedIDs.intersection(Set(questions.map(\.id))).count) / Double(questions.count)
    }

    var sourceCounts: [QuestionSource: Int] {
        Dictionary(grouping: questions, by: \.source).mapValues(\.count)
    }

    // MARK: - Private

    private func loadBundledQuestions() -> [Question]? {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bank = try? JSONDecoder().decode(QuestionBank.self, from: data) else {
            return nil
        }
        return bank.questions
    }

    private func loadImportedQuestions() -> [Question]? {
        let url = importedQuestionsURL()
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let questions = try? JSONDecoder().decode([Question].self, from: data) else {
            return nil
        }
        return questions
    }

    private func importedQuestionsURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("imported_questions.json")
    }

    private func deduplicated(_ items: [Question]) -> [Question] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }

    private func validate(_ question: Question) -> Bool {
        !question.id.isEmpty &&
        !question.question.isEmpty &&
        question.choices.count >= 2 &&
        question.choices.indices.contains(question.correctIndex)
    }
}
