import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @EnvironmentObject private var store: QuestionStore

    @State private var showImporter = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("덤프 JSON 가져오기")
                            .font(.headline)
                        Text("NCP-AIN 덤프를 JSON 형식으로 변환해 가져오면 암기 목록에 추가됩니다.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("가져오기") {
                    Button {
                        showImporter = true
                    } label: {
                        Label("JSON 파일 선택", systemImage: "doc.badge.plus")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("가져온 덤프 삭제", systemImage: "trash")
                    }
                }

                Section("JSON 형식") {
                    Text(sampleFormat)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }

                Section("덤프 변환 팁") {
                    Label("문제, 보기 4개, 정답 인덱스(0~3)만 필요합니다.", systemImage: "1.circle")
                    Label("category는 시험 6개 영역 중 하나를 사용하세요.", systemImage: "2.circle")
                    Label("중복 id는 자동으로 제거됩니다.", systemImage: "3.circle")
                }

                Section("카테고리 값") {
                    ForEach(QuestionCategory.allCases) { category in
                        Text(category.rawValue)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("덤프 관리")
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("덤프 가져오기", isPresented: $showAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
            .confirmationDialog("가져온 덤프를 삭제할까요?", isPresented: $showDeleteConfirm) {
                Button("삭제", role: .destructive) {
                    do {
                        try store.removeImportedQuestions()
                        alertMessage = "가져온 덤프가 삭제되었습니다."
                        showAlert = true
                    } catch {
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            }
        }
    }

    private var sampleFormat: String {
        """
        {
          "version": "1.0",
          "questions": [
            {
              "id": "dump-001",
              "category": "Spectrum Networking",
              "question": "문제 내용",
      "choices": ["보기1", "보기2", "보기3", "보기4"],
      "correctIndices": [0],
      "answerKey": "A",
      "isMultiSelect": false,
      "source": "Dump"
            }
          ]
        }
        """
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            alertMessage = error.localizedDescription
            showAlert = true
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                alertMessage = "파일 접근 권한이 없습니다."
                showAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let count = try store.importDump(from: url)
                alertMessage = "\(count)개 문제를 가져왔습니다."
                showAlert = true
            } catch {
                alertMessage = "가져오기 실패: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    ImportView()
        .environmentObject(QuestionStore())
}
