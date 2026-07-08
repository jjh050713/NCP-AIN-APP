# NCP-AIN 앱 설치 가이드 (iPhone)

## 중요: iOS 설치 파일(.ipa) 안내

iOS 앱은 **Apple 코드 서명**이 필요합니다. 이 저장소에는 **소스 코드 + 빌드 스크립트**가 포함되어 있으며, **실제 iPhone 설치**는 Mac + Xcode 또는 Apple Developer 계정이 필요합니다.

| 방법 | 난이도 | 비용 | 실기기 설치 |
|------|--------|------|------------|
| **Xcode 직접 설치** | ★ 쉬움 | 무료 (Apple ID) | ✅ |
| **TestFlight** | ★★ | $99/년 (Developer) | ✅ |
| **Ad Hoc IPA** | ★★★ | $99/년 | ✅ (등록 기기만) |
| **App Store** | ★★★★ | $99/년 | ✅ |

---

## 방법 1: Mac + Xcode로 iPhone에 바로 설치 (추천)

### 요구사항
- Mac (macOS Sonoma 이상)
- **Xcode 15+** ([Mac App Store](https://apps.apple.com/app/xcode/id497799835))
- iPhone (iOS **17+**)
- 무료 Apple ID

### 단계

1. 저장소 클론
   ```bash
   git clone https://github.com/jjh050713/NCP-AIN-APP.git
   cd NCP-AIN-APP
   ```

2. Xcode에서 프로젝트 열기
   ```bash
   open NCPAINApp/NCPAINApp.xcodeproj
   ```

3. **Signing & Capabilities** 설정
   - Target `NCPAINApp` 선택
   - Team: 본인 Apple ID 선택
   - Bundle Identifier: 고유값으로 변경 (예: `com.yourname.ncpain`)

4. iPhone을 USB로 연결 → 상단 기기에서 본인 iPhone 선택

5. **Run (⌘R)** → iPhone에 앱 설치

6. iPhone **설정 → 일반 → VPN 및 기기 관리**에서 개발자 앱 신뢰

---

## 방법 2: IPA 파일 빌드 (Mac)

```bash
# Apple Developer Team ID 설정 (Xcode → Settings → Accounts에서 확인)
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"

chmod +x scripts/build-ios.sh
./scripts/build-ios.sh
```

성공 시: `build/NCPAINApp.ipa`

---

## 방법 3: GitHub Actions 빌드 아티팩트

1. GitHub 저장소 → **Actions** → **iOS Build** 워크플로우
2. 실행 완료 후 **Artifacts** 다운로드
   - `NCPAINApp-Simulator-iPhone.zip` — 시뮬레이터용 (실기기 X)
   - `NCPAINApp-unsigned.ipa` — 참고용 (서명 없음, 실기기 설치 불가)

> 실기기용 IPA는 **본인 Mac에서 서명** 후 설치해야 합니다.

---

## 앱 정보

| 항목 | 값 |
|------|-----|
| 앱 이름 | NCP-AIN 암기 |
| 버전 | 1.0.0 (Build 2) |
| 최소 iOS | 17.0 |
| 기기 | iPhone 전용 (세로 모드) |
| 문항 수 | 245 (Dump 180 + 연습/공식 65) |

---

## iOS 최적화 적용 사항

- iPhone 전용 (`TARGETED_DEVICE_FAMILY = 1`)
- 세로 모드 고정
- Safe Area / 홈 인디케이터 대응
- 햅틱 피드백 (정답 확인, 페이지 전환)
- 백그라운드 JSON 로딩 (245문항 빠른 시작)
- VoiceOver 접근성 라벨
- 다크/라이트 모드 시스템 색상 지원
- 앱 아이콘 + 런치 스크린

---

## 문제 해결

**"Signing requires a development team"**
→ Xcode에서 Apple ID 로그인 후 Team 선택

**"Unable to install"**
→ iPhone iOS 버전이 17 이상인지 확인

**앱이 7일 후 만료 (무료 Apple ID)**
→ Xcode에서 다시 Run하여 재설치

---

## 문의

추가 덤프 JSON은 앱 **덤프** 탭에서 가져올 수 있습니다.
