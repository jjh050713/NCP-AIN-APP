import SwiftUI

struct QuestionCardView: View {
    let question: Question
    let index: Int
    let total: Int
    let isBookmarked: Bool
    let onToggleBookmark: () -> Void

    private let answerLabels = ["A", "B", "C", "D", "E", "F"]

    private var correctAnswers: [(label: String, text: String)] {
        question.correctIndices.enumerated().compactMap { offset, index in
            guard question.choices.indices.contains(index) else { return nil }
            let label = offset < answerLabels.count ? answerLabels[offset] : "\(offset + 1)"
            return (label, question.choices[index])
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                flashcard
            }
            .padding(.vertical, 8)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Q\(index) / \(total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Label(question.category.rawValue, systemImage: question.category.icon)
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            Spacer()

            Button(action: onToggleBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(isBookmarked ? .yellow : .secondary)
            }

            Text(question.source.rawValue)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
    }

    private var flashcard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if question.isMultiSelect {
                Label("복수 정답", systemImage: "checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            HStack(alignment: .top, spacing: 6) {
                Text("Q:")
                    .font(.body.weight(.bold))
                Text(question.question)
                    .font(.body.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            Divider()

            ForEach(Array(correctAnswers.enumerated()), id: \.offset) { _, answer in
                HStack(alignment: .top, spacing: 6) {
                    Text("\(answer.label) :")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.green)
                    Text(answer.text)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.green)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    QuestionCardView(
        question: Question(
            id: "preview",
            category: .spectrumNetworking,
            question: "RoCE 환경에서 ECN을 활성화하는 주요 목적은?",
            choices: [
                "패킷 드롭 없이 혼잡 제어",
                "VLAN 태깅",
                "BGP 라우팅",
                "스패닝 트리 차단"
            ],
            correctIndices: [0],
            answerKey: "A",
            source: .practice
        ),
        index: 1,
        total: 10,
        isBookmarked: false,
        onToggleBookmark: {}
    )
    .padding()
}
