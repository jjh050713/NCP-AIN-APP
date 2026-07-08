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
    let correctIndex: Int
    let source: QuestionSource

    var correctAnswer: String {
        guard choices.indices.contains(correctIndex) else { return "" }
        return choices[correctIndex]
    }
}

struct QuestionBank: Codable {
    let version: String
    let questions: [Question]
}
