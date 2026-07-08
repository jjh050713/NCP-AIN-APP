import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: QuestionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    progressCard
                    categorySection
                    sourceSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("NCP-AIN")
            .overlay {
                if store.isLoading {
                    ProgressView("문제 로딩 중…")
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("NVIDIA Certified Professional", systemImage: "checkmark.seal.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("AI Networking (NCP-AIN)")
                .font(.title2.bold())

            Text("덤프 암기 모드 — 문제와 보기만 표시하고 정답을 확인하세요.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("학습 진행률")
                    .font(.headline)
                Spacer()
                Text("\(Int(store.progress * 100))%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.green)
            }

            ProgressView(value: store.progress)
                .tint(.green)

            HStack {
                statItem(title: "전체", value: "\(store.questions.count)")
                Divider()
                statItem(title: "북마크", value: "\(store.bookmarkedQuestions().count)")
                Divider()
                statItem(title: "카테고리", value: "\(QuestionCategory.allCases.count)")
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("시험 범위")
                .font(.headline)

            ForEach(QuestionCategory.allCases) { category in
                let count = store.questions(in: category).count
                NavigationLink {
                    StudyView(initialCategory: category)
                } label: {
                    HStack {
                        Image(systemName: category.icon)
                            .frame(width: 28)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.rawValue)
                                .font(.subheadline.weight(.medium))
                            Text("시험 비중 \(category.examWeight) · \(count)문제")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("문제 출처")
                .font(.headline)

            ForEach([QuestionSource.official, .practice, .dump], id: \.self) { source in
                HStack {
                    Text(source.rawValue)
                    Spacer()
                    Text("\(store.sourceCounts[source] ?? 0)")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    HomeView()
        .environmentObject(QuestionStore())
}
