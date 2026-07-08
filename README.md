# NCP-AIN 암기 앱 (iOS)

NVIDIA **NCP-AIN** (AI Networking) 자격증 덤프 암기용 **네이티브 iOS 앱**입니다.

문제와 보기만 표시하고, **정답 보기** 버튼으로 암기하는 방식입니다.

## 주요 기능

- **암기 모드**: 문제 + 객관식 보기 → 정답 확인
- **카테고리 필터**: 공식 시험 6개 영역별 학습
- **셔플 / 북마크**: 어려운 문제 반복 학습
- **덤프 가져오기**: JSON 파일로 덤프 문제 추가
- **진행률 추적**: 정답을 확인한 문제 비율 표시

## 내장 문제

| 출처 | 문항 수 | 설명 |
|------|--------|------|
| **Dump** | 180 | Korea + HWP 120문제 덤프 (중복 제거) |
| **Official Topic** | 30 | NVIDIA 공식 문서 기반 (NVLink, Spectrum-X, SHARP, SuperNIC 등) |
| **Practice** | 35 | 공식 자료 기반 연습 문제 |
| **합계** | **245** | |

### NVIDIA 공식 기술 문제 (`dumps/nvidia_official_tech.json`)

[NVIDIA 공식 문서](https://www.nvidia.com/en-us/data-center/nvlink/), [Spectrum-X Docs](https://docs.nvidia.com/networking/display/kubernetes2640/spectrum-x/spectrum-x.html), [UFM SHARP](https://docs.nvidia.com/networking/display/UFMEnterpriseUMv6171/appendix-nvidia-sharp-integration.pdf) 기반:

- **NVLink**: Hopper 900GB/s, Blackwell 1.8TB/s, Rubin 3.6TB/s, NVL72, Fabric Manager
- **Spectrum-X / SuperNIC**: BlueField-3(a2dc), ConnectX-8(1023), hwplb, spectrumXOptimized
- **SHARP / InfiniBand**: AllReduce 오프로드, UFM sharp_enabled, OpenSM 설정
- **Kubernetes**: Network Operator, NIC Configuration Operator

### 덤프 파일

- `dumps/source_dump.json` — Korea v12.95 + 잡다한 Dump 1
- `dumps/ncp_ain_exam_120.json` — NCP-AIN-EXAM 정리 120문제 HWP (151항목)

## 문제 은행 병합

```bash
cd scripts
python3 convert_user_dump.py ../dumps/source_dump.json -o /tmp/dump_korea.json
python3 convert_exam_dump.py ../dumps/ncp_ain_exam_120.json -o /tmp/dump_hwp120.json
python3 merge_question_banks.py /tmp/dump_korea.json /tmp/dump_hwp120.json ../dumps/supplementary_practice.json ../dumps/nvidia_official_tech.json -o ../NCPAINApp/NCPAINApp/Resources/questions.json
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
