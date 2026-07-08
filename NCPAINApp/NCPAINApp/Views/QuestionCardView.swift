import SwiftUI

struct QuestionCardView: View {
    let question: Question
    let index: Int
    let total: Int
    let isRevealed: Bool
    let isBookmarked: Bool
    let onReveal: () -> Void
    let onToggleBookmark: () -> Void

    private let choiceLabels = ["A", "B", "C", "D", "E", "F"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                questionText
                choicesList
                revealSection
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

    private var questionText: some View {
        VStack(alignment: .leading, spacing: 8) {
            if question.isMultiSelect {
                Label("복수 정답", systemImage: "checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Text(question.question)
                .font(.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }

    private var choicesList: some View {
        VStack(spacing: 10) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { offset, choice in
                choiceRow(index: offset, text: choice)
            }
        }
    }

    private func choiceRow(index: Int, text: String) -> some View {
        let label = index < choiceLabels.count ? choiceLabels[index] : "\(index + 1)"
        let isCorrect = isRevealed && question.correctIndices.contains(index)

        return HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.subheadline.bold().monospacedDigit())
                .frame(width: 24, height: 24)
                .background(circleColor(isCorrect: isCorrect))
                .foregroundStyle(isCorrect ? .white : .primary)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(rowBackground(isCorrect: isCorrect), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCorrect ? Color.green : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("보기 \(label), \(text)")
        .accessibilityAddTraits(isCorrect ? .isSelected : [])
    }

    private var revealSection: some View {
        VStack(spacing: 12) {
            if isRevealed {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("정답: \(question.correctAnswerLabel)")
                        .font(.subheadline.weight(.semibold))
                    if question.isMultiSelect {
                        Text(question.correctAnswer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            } else {
                Button(action: onReveal) {
                    Label("정답 보기", systemImage: "eye.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(.top, 4)
    }

    private func choiceLabel(for index: Int) -> String {
        index < choiceLabels.count ? choiceLabels[index] : "\(index + 1)"
    }

    private func circleColor(isCorrect: Bool) -> Color {
        isCorrect ? .green : Color(.systemGray4)
    }

    private func rowBackground(isCorrect: Bool) -> Color {
        isCorrect ? Color.green.opacity(0.12) : Color(.secondarySystemGroupedBackground)
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
        isRevealed: false,
        isBookmarked: false,
        onReveal: {},
        onToggleBookmark: {}
    )
    .padding()
}
