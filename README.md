# NCP-AIN 암기 앱 (iOS)

NVIDIA **NCP-AIN** (AI Networking) 자격증 덤프 암기용 **네이티브 iOS 앱**입니다.

문제와 보기만 표시하고, **정답 보기** 버튼으로 암기하는 방식입니다.

## 주요 기능

- **암기 모드**: 문제 + 객관식 보기 → 정답 확인
- **카테고리 필터**: 공식 시험 6개 영역별 학습
- **셔플 / 북마크**: 어려운 문제 반복 학습
- **덤프 가져오기**: JSON 파일로 덤프 문제 추가
- **진행률 추적**: 정답을 확인한 문제 비율 표시

## 내장 문제 (Korea Dump v12.95)

| 항목 | 내용 |
|------|------|
| 출처 | `Korea_Dump_v12.95.docx` + `잡다한 Dump 1.docx` |
| 고유 문항 | **90문항** (중복 20문항 자동 제거) |
| 복수 정답 | **7문항** (AD, AB, AC, BC, BD 등) |

| 영역 | 문항 수 |
|------|--------|
| Spectrum Networking | 44 |
| InfiniBand Networking | 21 |
| Troubleshooting Tools | 11 |
| AI Data Center Design | 7 |
| Kubernetes Integration | 4 |
| Automation & Configuration | 3 |

## 덤프 추가/재변환

원본 덤프 JSON을 `dumps/source_dump.json`에 넣고:

```bash
python3 scripts/convert_user_dump.py dumps/source_dump.json
```

## 빌드 방법 (macOS + Xcode)

1. Mac에서 저장소를 클론합니다.
2. `NCPAINApp/NCPAINApp.xcodeproj` 를 Xcode로 엽니다.
3. **Signing & Capabilities** 에서 본인 Apple Developer Team을 선택합니다.
4. iPhone 시뮬레이터 또는 실제 기기에서 Run (⌘R).

**요구사항**: Xcode 15+, iOS 17+

## 덤프 추가 방법

### 1) 앱에서 직접 가져오기

1. 앱 **덤프** 탭 → **JSON 파일 선택**
2. `samples/dump_template.json` 형식의 파일 선택

### 2) JSON 형식

```json
{
  "version": "1.0",
  "questions": [
    {
      "id": "dump-001",
      "category": "Spectrum Networking",
      "question": "문제 내용",
      "choices": ["보기1", "보기2", "보기3", "보기4"],
      "correctIndex": 0,
      "source": "Dump"
    }
  ]
}
```

**category** 값 (정확히 일치):

- `AI Data Center Design`
- `Spectrum Networking`
- `InfiniBand Networking`
- `Kubernetes Integration`
- `Troubleshooting Tools`
- `Automation & Configuration`

**correctIndices**: 0 = A, 1 = B, 2 = C, 3 = D (복수 정답은 배열로: `[0, 3]` = AD)

### 3) 텍스트 덤프 변환 스크립트

```bash
python3 scripts/convert_dump.py your_dump.txt -o dump_import.json
```

입력 예시 (`your_dump.txt`):

```text
---
CATEGORY: Spectrum Networking
Q: RoCE에서 ECN의 역할은?
A) 혼잡 알림
B) VLAN 태깅
C) BGP 라우팅
D) STP 차단
ANSWER: A
---
```

## 덤프 파일 올려주시면

아래 형식 중 편한 것으로 보내주시면 앱에 맞게 변환해 드릴 수 있습니다.

- PDF / Word / Excel 덤프
- 텍스트 (문제+보기+정답)
- 기존 JSON

## 프로젝트 구조

```
NCPAINApp/
├── NCPAINApp.xcodeproj/
└── NCPAINApp/
    ├── Models/Question.swift
    ├── Services/QuestionStore.swift
    ├── Views/          # Home, Study, Import
    └── Resources/questions.json
```

## 참고

- [NVIDIA NCP-AIN 공식 페이지](https://www.nvidia.com/en-us/learn/certification/ai-networking-professional/)
- 이 앱은 NVIDIA 공식 앱이 아닌 **개인 학습용** 프로젝트입니다.
