import Foundation

enum QuestionCategory: String, Codable, CaseIterable, Identifiable {
    case aiDataCenter = "AI Data Center Design"
    case spectrumNetworking = "Spectrum Networking"
    case infinibandNetworking = "InfiniBand Networking"
    case kubernetes = "Kubernetes Integration"
    case troubleshooting = "Troubleshooting Tools"
    case automation = "Automation & Configuration"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .aiDataCenter: return "building.2"
        case .spectrumNetworking: return "network"
        case .infinibandNetworking: return "cable.connector"
        case .kubernetes: return "cube"
        case .troubleshooting: return "wrench.and.screwdriver"
        case .automation: return "gearshape.2"
        }
    }

    var examWeight: String {
        switch self {
        case .aiDataCenter: return "5%"
        case .spectrumNetworking: return "30%"
        case .infinibandNetworking: return "30%"
        case .kubernetes: return "5%"
        case .troubleshooting: return "20%"
        case .automation: return "10%"
        }
    }
}

enum QuestionSource: String, Codable {
    case official = "Official Topic"
    case practice = "Practice"
    case dump = "Dump"
}

struct Question: Codable, Identifiable, Hashable {
    let id: String
    let category: QuestionCategory
    let question: String
    let choices: [String]
    let correctIndices: [Int]
    let answerKey: String?
    let isMultiSelect: Bool
    let source: QuestionSource

    var correctIndex: Int {
        correctIndices.first ?? 0
    }

    var correctAnswer: String {
        correctIndices
            .compactMap { choices.indices.contains($0) ? choices[$0] : nil }
            .joined(separator: " / ")
    }

    var correctAnswerLabel: String {
        if let answerKey, !answerKey.isEmpty {
            return answerKey
        }
        return correctIndices
            .map { label(for: $0) }
            .joined(separator: ", ")
    }

    func label(for index: Int) -> String {
        let labels = ["A", "B", "C", "D", "E", "F"]
        return index < labels.count ? labels[index] : "\(index + 1)"
    }

    enum CodingKeys: String, CodingKey {
        case id, category, question, choices, correctIndices, answerKey, isMultiSelect, source
        case correctIndex
    }

    init(
        id: String,
        category: QuestionCategory,
        question: String,
        choices: [String],
        correctIndices: [Int],
        answerKey: String? = nil,
        isMultiSelect: Bool = false,
        source: QuestionSource
    ) {
        self.id = id
        self.category = category
        self.question = question
        self.choices = choices
        self.correctIndices = correctIndices
        self.answerKey = answerKey
        self.isMultiSelect = isMultiSelect || correctIndices.count > 1
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        category = try container.decode(QuestionCategory.self, forKey: .category)
        question = try container.decode(String.self, forKey: .question)
        choices = try container.decode([String].self, forKey: .choices)
        source = try container.decode(QuestionSource.self, forKey: .source)
        answerKey = try container.decodeIfPresent(String.self, forKey: .answerKey)

        if let indices = try container.decodeIfPresent([Int].self, forKey: .correctIndices), !indices.isEmpty {
            correctIndices = indices
        } else if let index = try container.decodeIfPresent(Int.self, forKey: .correctIndex) {
            correctIndices = [index]
        } else {
            correctIndices = [0]
        }

        let decodedMulti = try container.decodeIfPresent(Bool.self, forKey: .isMultiSelect) ?? false
        isMultiSelect = decodedMulti || correctIndices.count > 1
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
        try container.encode(question, forKey: .question)
        try container.encode(choices, forKey: .choices)
        try container.encode(correctIndices, forKey: .correctIndices)
        try container.encodeIfPresent(answerKey, forKey: .answerKey)
        try container.encode(isMultiSelect, forKey: .isMultiSelect)
        try container.encode(source, forKey: .source)
        if correctIndices.count == 1 {
            try container.encode(correctIndices[0], forKey: .correctIndex)
        }
    }
}

struct QuestionBank: Codable {
    let version: String
    let questions: [Question]
}
