import SwiftUI

struct MockExamView: View {
    @EnvironmentObject private var examStore: MockExamStore

    var body: some View {
        NavigationStack {
            Group {
                if examStore.isLoading {
                    ProgressView("모의고사 로딩 중…")
                } else if examStore.questions.isEmpty {
                    ContentUnavailableView {
                        Label("문제를 불러올 수 없습니다", systemImage: "exclamationmark.triangle")
                    }
                } else if examStore.state.finished, let score = examStore.state.score {
                    ExamResultView(score: score)
                } else if !examStore.state.started {
                    ExamIntroView()
                } else {
                    ExamQuestionView()
                }
            }
            .navigationTitle("모의고사")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                examStore.loadIfNeeded()
            }
        }
    }
}

private struct ExamIntroView: View {
    @EnvironmentObject private var examStore: MockExamStore
    @State private var showRestartConfirm = false

    private var hasProgress: Bool { examStore.answeredCount > 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("실전 모의고사", systemImage: "doc.text.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("기출 120제")
                        .font(.title2.bold())
                    Text("실제 시험처럼 오답 보기도 함께 표시됩니다. 120문제를 모두 풀면 몇 개 맞았는지 채점 결과를 확인할 수 있습니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16))

                HStack {
                    statItem(title: "전체 문제", value: "\(examStore.questions.count)")
                    Divider()
                    statItem(title: "답변 완료", value: "\(examStore.answeredCount)")
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    examStore.start()
                } label: {
                    Text(hasProgress ? "이어서 풀기" : "모의고사 시작")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                if hasProgress {
                    Button("처음부터 다시 시작", role: .destructive) {
                        showRestartConfirm = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .confirmationDialog(
            "처음부터 다시 시작할까요? 진행 상황이 모두 초기화됩니다.",
            isPresented: $showRestartConfirm,
            titleVisibility: .visible
        ) {
            Button("다시 시작", role: .destructive) {
                examStore.retry()
            }
            Button("취소", role: .cancel) {}
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ExamQuestionView: View {
    @EnvironmentObject private var examStore: MockExamStore
    @State private var showSubmitConfirm = false

    private let labels = ["A", "B", "C", "D", "E", "F"]

    var body: some View {
        VStack(spacing: 0) {
            if let question = examStore.currentQuestion {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        progressSection
                        questionCard(question)
                        choicesList(question)
                    }
                    .padding()
                }

                navigationBar
            }
        }
        .confirmationDialog(
            "아직 \(examStore.unansweredCount)개 문제에 답하지 않았습니다. 그래도 제출할까요?",
            isPresented: $showSubmitConfirm,
            titleVisibility: .visible
        ) {
            Button("제출하기", role: .destructive) {
                examStore.submit()
                HapticManager.success()
            }
            Button("취소", role: .cancel) {}
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(examStore.currentIndex + 1) / \(examStore.questions.count)")
                    .font(.caption.monospacedDigit())
                Spacer()
                Text("\(examStore.answeredCount)개 답변 완료")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(examStore.currentIndex + 1), total: Double(examStore.questions.count))
                .tint(.green)
        }
    }

    private func questionCard(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(question.category.rawValue, systemImage: question.category.icon)
                .font(.caption)
                .foregroundStyle(.green)

            if question.isMultiSelect {
                Label("복수 정답 (모두 선택)", systemImage: "checklist")
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

    private func choicesList(_ question: Question) -> some View {
        let selected = examStore.selectedIndices(for: question)

        return VStack(spacing: 10) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { offset, text in
                let isSelected = selected.contains(offset)
                let label = offset < labels.count ? labels[offset] : "\(offset + 1)"

                Button {
                    examStore.toggleChoice(question, index: offset)
                    HapticManager.lightTap()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Text(label)
                            .font(.subheadline.bold().monospacedDigit())
                            .frame(width: 24, height: 24)
                            .background(isSelected ? Color.green : Color(.systemGray4))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .clipShape(Circle())

                        Text(text)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.primary)
                    }
                    .padding(12)
                    .background(
                        isSelected ? Color.green.opacity(0.12) : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(action: examStore.goPrevious) {
                Label("이전", systemImage: "chevron.left")
            }
            .disabled(examStore.currentIndex == 0)

            Spacer()

            if examStore.isLastQuestion {
                Button {
                    if examStore.unansweredCount > 0 {
                        showSubmitConfirm = true
                    } else {
                        examStore.submit()
                        HapticManager.success()
                    }
                } label: {
                    Text("제출하고 채점하기")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                Button(action: examStore.goNext) {
                    Label("다음", systemImage: "chevron.right")
                }
            }
        }
        .padding()
        .background(.bar)
        .safeAreaPadding(.bottom, 4)
    }
}

private struct ExamResultView: View {
    @EnvironmentObject private var examStore: MockExamStore
    let score: ExamScore
    @State private var showRetryConfirm = false

    private let labels = ["A", "B", "C", "D", "E", "F"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Text("모의고사 결과")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(score.correct)")
                            .font(.system(size: 44, weight: .heavy))
                            .foregroundStyle(.green)
                        Text("/ \(score.total)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text("\(formattedPercent)점")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ProgressView(value: score.percent, total: 100)
                        .tint(.green)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    showRetryConfirm = true
                } label: {
                    Text("다시 도전하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                let wrong = examStore.wrongQuestions()
                if wrong.isEmpty {
                    Text("🎉 전 문제 정답입니다!")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.background, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("틀린 문제 (\(wrong.count)개)")
                            .font(.headline)

                        ForEach(wrong) { question in
                            reviewRow(question)
                        }
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .confirmationDialog(
            "새로운 모의고사를 시작할까요? 이전 결과는 사라집니다.",
            isPresented: $showRetryConfirm,
            titleVisibility: .visible
        ) {
            Button("다시 시작", role: .destructive) {
                examStore.retry()
            }
            Button("취소", role: .cancel) {}
        }
    }

    private var formattedPercent: String {
        score.percent == score.percent.rounded()
            ? String(format: "%.0f", score.percent)
            : String(format: "%.1f", score.percent)
    }

    private func reviewRow(_ question: Question) -> some View {
        let given = examStore.selectedIndices(for: question).sorted()
        let givenLabel = given.isEmpty
            ? "(답변 없음)"
            : given.map { $0 < labels.count ? labels[$0] : "\($0 + 1)" }.joined(separator: ", ")
        let answerLabel = question.correctAnswerLabel

        return VStack(alignment: .leading, spacing: 4) {
            Text(question.question)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            Text("내 답: \(givenLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("정답: \(answerLabel)")
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

#Preview {
    MockExamView()
        .environmentObject(MockExamStore())
}
