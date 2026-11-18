# icodebroker 무료 프로그램 다운로드 사이트 계획

작성일: 2026-11-18 (3차 수정) · 상태: 모든 결정 확정, 구현 단계

## 1. 목표

`D:\UTILITY` 아래 WPF 앱들을 누구나 무료로 내려받을 수 있게 <https://icodebroker.github.io/> 에 다운로드 사이트를 만든다.

- **첫 화면 하나에서 모든 프로그램을 내려받을 수 있다.** 카드마다 스크린샷과 다운로드 버튼이 같이 있다.
- 한국어와 영어를 모두 지원한다.
- 회원 가입·광고·중간 확인 화면 없이 버튼 한 번에 zip을 받는다.
- "무료 사용, 무보증, 재배포 금지"를 사이트와 zip 안에 모두 표시한다.
- 앱마다 그 앱을 소개하는 페이지가 있다.

## 2. 확정 결정

| 번호 | 결정 |
| --- | --- |
| 1 | 자식 폴더는 37개다(BigArca 삭제됨, 2026-11-18 확인) |
| 2 | exe를 **zip으로 압축해** 이 저장소(`icodebroker.github.io`)의 **GitHub Releases**에 올린다 |
| 3 | 라이선스: **무료 사용, 무보증, 재배포 금지** (프리웨어) |
| 4 | **BigPlayer는 일단 제외** (libmpv GPL 문제는 나중에 다시 판단) |
| 5 | 업로드는 **gh CLI**로 한다. 2.105.0 설치, `icodebroker` 계정 로그인 완료(repo 권한) |
| 6 | 사이트는 **한국어·영어** 두 가지 |
| 7 | 스크린샷은 **빈 자리 이미지 하나**를 만들어 모든 앱이 같이 쓴다. 나중에 앱별 이미지로 바꾼다 |
| 8 | 디자인: 모던하지만 IT 회사 느낌은 피하고, **친근하고 깔끔한 무료 프로그램 배포 사이트** |
| 9 | 사이트 이름: **icodebroker** |
| 10 | 앱별 상세 페이지는 **그 앱의 소개 페이지**로 디자인한다(6절) |

## 3. 대상 앱

37개에서 BigChat, BigVideoStream, BigPlayer를 빼면 **34개**다. 모두 publish 폴더에 exe가 하나씩 있다(.NET 10 단일 파일, self-contained, win-x64, 버전 1.0.0).

| 분류 키 | 한국어 | English | 앱 |
| --- | --- | --- | --- |
| files | 파일·디스크 | Files & Disks | BigExplorer, BigDiskSize, BigDisk, BigZIP, BigFTP, BigS3 |
| docs | 편집·문서 | Editing & Docs | BigEdit, BigJSON, BigCSV, BigFormula, BigMindMap, BigMEMO |
| dev | 개발·데이터베이스 | Dev & Database | BigSQL, BigMigration, BigCURL, BigDocker, BigOpenCode, BigClaude |
| network | 네트워크·보안 | Network & Security | BigPacket, BigDetection, BigRemote |
| media | 미디어 | Media | BigImageView, BigPiano |
| desktop | 데스크톱 도구 | Desktop Tools | BigCalculator, BigCloser, BigWatch, BigView, BigKeyboard, BigReader, BigStock |
| algo | 알고리즘 시각화 | Algorithm Visualizers | BigMaze, BigGraph, BigHuffman, BigClustering |

분류와 한 줄 설명은 메모와 소스를 바탕으로 초안을 쓰고 사용자 검토를 받는다.

### 크기

- exe 합계 약 2.38GB (BigPlayer 제외)
- zip 시험 결과: BigCalculator는 64.0MB에서 58.5MB(9% 감소), BigCSV는 136.0MB에서 57.1MB(58% 감소). 대부분 앱은 단일 파일 압축이 이미 되어 있어 10% 안팎만 줄어든다.

### publish 폴더에서 zip에 넣지 않는 것

- `CONFIGURATION\*.json` (내 PC 설정, 서버 목록·접속 정보가 있을 수 있음)
- `LOG\*.log`
- `MODEL\supertonic\*` (BigReader가 처음 실행될 때 알아서 내려받음)

## 4. 배포 파일 (zip과 Releases)

### zip 구성

```text
BigEdit-1.0.0-win-x64.zip
├─ BigEdit.exe
└─ README.txt      # 한국어·영어: 무료 사용·무보증·재배포 금지, 실행 방법, 설정 저장 위치, 제3자 라이선스 고지
```

- BigRemote zip에는 `FREERDP-LICENSE.txt`를 더 넣는다.
- 파일 이름 형식: `<앱>-<버전>-win-x64.zip`

### Releases

- 앱마다 릴리스 하나. 태그는 `<앱>-v<버전>` (예: `BigEdit-v1.0.0`)
- 릴리스 노트는 한국어·영어 짧은 소개와 zip SHA-256
- 다운로드 주소: `https://github.com/icodebroker/icodebroker.github.io/releases/download/BigEdit-v1.0.0/BigEdit-1.0.0-win-x64.zip`. 누르면 바로 내려받아진다.

### 무료·무보증·재배포 금지 문구

- 한국어: "이 프로그램은 개인·회사 모두 무료로 쓸 수 있습니다. 어떤 보증도 없이 '있는 그대로' 제공되며, 사용하면서 생긴 손해에 대해 제작자는 책임지지 않습니다. 이 프로그램을 다른 곳에 다시 올리거나 나눠 주는 것(재배포), 고치거나 판매하는 것은 금지합니다. 필요한 분께는 이 사이트 주소를 알려 주세요."
- English: "Free for personal and commercial use. Provided \"as is\", without warranty of any kind. The author is not liable for any damages arising from its use. Redistribution, modification, and resale are prohibited. Please share a link to this site instead."
- 짧은 문구(바닥글·카드 아래): "무료 사용 · 무보증 · 재배포 금지" / "Free to use · No warranty · No redistribution"

이 문구는 사이트 바닥글(짧게), 라이선스 페이지(전문), zip의 README.txt에 넣는다. 앱에 들어 있는 제3자 구성 요소(FreeRDP, 글꼴, .NET 런타임, NuGet 패키지)는 각자의 라이선스를 따른다고 함께 적는다. 재배포 금지는 내가 만든 코드에만 적용된다.

## 5. 사이트 구조

GitHub Pages 기본 Jekyll을 쓴다. 플러그인·Actions·빌드 도구는 쓰지 않는다. 기존 `theme: jekyll-theme-minimal`은 지우고 레이아웃을 직접 만든다.

```text
icodebroker.github.io/
├─ _config.yml              # title, lang, theme 줄 삭제
├─ _data/
│   ├─ apps.yml             # 앱 34개 (스크립트가 숫자를 채우고 사람이 설명을 씀)
│   └─ i18n.yml             # 화면 문구 ko/en (버튼, 안내, 분류 이름)
├─ _includes/
│   ├─ app-card.html        # 첫 화면 카드
│   ├─ header.html          # 로고, 언어 전환
│   └─ footer.html          # 무료·무보증·재배포 금지 짧은 문구, 라이선스 링크
├─ _layouts/
│   ├─ default.html
│   └─ app.html             # 앱 소개 페이지
├─ index.html               # 한국어 첫 화면  (/)
├─ en/index.html            # 영어 첫 화면    (/en/)
├─ apps/BigEdit.html        # 한국어 소개     (/apps/BigEdit/)   ← 스크립트가 만드는 앞부분만 있는 파일
├─ en/apps/BigEdit.html     # 영어 소개       (/en/apps/BigEdit/)
├─ license.html, en/license.html   # 무료·무보증·재배포 금지 전문 + 제3자 라이선스
├─ help.html, en/help.html         # SmartScreen 경고, 해시 확인, 지우는 법
├─ assets/
│   ├─ css/site.css
│   ├─ js/site.js           # 분류 필터, 검색, 언어 기억 (외부 라이브러리 없음)
│   ├─ icons/BigEdit.png    # .ico에서 변환 (128px)
│   └─ screenshots/placeholder.png   # 빈 스크린샷 이미지
├─ README.md
└─ tools/Publish-Apps.ps1
```

### `_data/apps.yml` 항목

```yaml
- name: BigEdit
  category: docs
  summary:                # 카드에 쓰는 한 줄 설명
    ko: 나눔고딕코딩을 내장한 탭 텍스트 편집기
    en: Tabbed text editor with a built-in coding font
  tagline:                # 소개 페이지 맨 위 큰 문장
    ko: 코드도 메모도, 가볍게 열고 편하게 고치세요
    en: Open light, edit comfortably — code or notes
  intro:                  # 소개 페이지 첫 단락 (2~3문장)
    ko: …
    en: …
  features:               # 소개 페이지 기능 카드 (3~6개)
    - title: { ko: 여러 파일을 탭으로, en: Tabs for every file }
      text:  { ko: …, en: … }
  uses:                   # 이럴 때 쓰세요 (2~4개, 선택)
    ko: [설정 파일을 빠르게 고칠 때, …]
    en: [Quick edits to config files, …]
  settings_path: '%APPDATA%\BigEdit'   # 설정 저장 위치 (지우는 법 안내에 사용)
  version: 1.0.0
  zip: BigEdit-1.0.0-win-x64.zip
  size: 61234567          # zip 크기(바이트)
  sha256: "…"
  url: https://github.com/icodebroker/icodebroker.github.io/releases/download/BigEdit-v1.0.0/BigEdit-1.0.0-win-x64.zip
  released: 2026-11-18
  screenshot:             # 비어 있으면 placeholder.png
```

상세 페이지 파일(`apps/BigEdit.html`)에는 `layout: app`, `app: BigEdit`, `lang: ko`, `permalink`만 들어 있다. 내용은 모두 `apps.yml`과 `i18n.yml`에서 가져온다.

### 두 언어 처리

- `/`는 한국어, `/en/`은 영어다. 머리글의 `한국어 | English` 버튼은 같은 내용의 반대 언어 주소로 간다.
- 첫 방문에 브라우저 언어가 한국어가 아니고 저장된 선택도 없으면 `/`에서 `/en/`으로 보낸다. 사용자가 고른 언어는 `localStorage`에 기억한다(읽기·쓰기는 try/catch로 감싸고, 실패하면 그냥 한국어로 보인다).
- `<html lang>`, `<link rel="alternate" hreflang>`을 페이지마다 넣는다.

## 6. 디자인

### 방향

"믿을 수 있는 동네 무료 소프트웨어 가게" 느낌. 기업 소개 페이지처럼 딱딱하지 않게, 앱 스토어처럼 훑어보고 바로 받게 한다.

- 색: 따뜻한 미색 배경(#FFFBF5 근처), 주 색은 부드러운 초록(다운로드 버튼, "무료" 배지), 포인트로 연한 노랑·하늘색. 남색·검정 위주의 IT 회사 색은 피한다.
- 모양: 둥근 모서리(카드 16px, 버튼은 알약 모양), 옅은 그림자, 넉넉한 여백
- 글꼴: Pretendard(한국어·영어 모두 자연스러움, jsDelivr 버전 고정)
- 말투: "설치 없이 바로 쓰는 무료 프로그램 34개", "받아서 바로 실행하세요"처럼 쉬운 문장
- 다크 모드: 시스템 설정을 따른다. 배경은 따뜻한 짙은 회색으로, 초록 버튼은 그대로 둔다.

### 첫 화면 (한 페이지에서 전부 다운로드)

```text
┌──────────────────────────────────────────────────────────┐
│ [로고] icodebroker                         한국어 | English │
├──────────────────────────────────────────────────────────┤
│  설치 없이 바로 쓰는 무료 윈도우 프로그램 34개              │
│  ✓ 완전 무료  ✓ 광고 없음  ✓ 설치 필요 없음  ✓ Windows 10/11 │
├──────────────────────────────────────────────────────────┤
│ [전체] [파일·디스크] [편집·문서] [개발] ...   [🔍 검색    ] │
├──────────────────────────────────────────────────────────┤
│ ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│ │ 스크린샷   │ │ 스크린샷   │ │ 스크린샷   │              │
│ │ (16:10)    │ │            │ │            │              │
│ ├────────────┤ ├────────────┤ ├────────────┤              │
│ │[아이콘]이름│ │            │ │            │              │
│ │ 한 줄 설명 │ │            │ │            │              │
│ │ v1.0.0·58MB│ │            │ │            │              │
│ │[⬇ 무료 다운로드]│        │ │            │              │
│ │  자세히 보기 →│          │ │            │              │
│ └────────────┘ └────────────┘ └────────────┘              │
│   ... 34개 (넓은 화면 3~4열, 태블릿 2열, 휴대폰 1열)        │
├──────────────────────────────────────────────────────────┤
│ 처음 받으셨나요? SmartScreen 경고가 뜨면 → 도움말          │
│ 무료 사용 · 무보증 · 재배포 금지 · 라이선스 · GitHub        │
└──────────────────────────────────────────────────────────┘
```

- 카드의 다운로드 버튼이 바로 zip 주소다. 상세 페이지를 거치지 않는다.
- 분류 버튼과 검색은 자바스크립트로 카드를 숨기거나 보이기만 한다. 자바스크립트가 꺼져 있어도 34개가 모두 보이고 내려받을 수 있다.
- 스크린샷은 `loading="lazy"`, 가로세로 크기를 지정해 화면이 밀리지 않게 한다.
- 휴대폰에서 열어도 깨지지 않게 한다(좌우 여백 16px, 가로 스크롤 없음). 휴대폰에서는 "Windows용 프로그램입니다" 안내를 보인다.

### 앱 소개 페이지

사양표가 아니라 **그 앱 하나를 소개하는 작은 홈페이지**처럼 만든다. 위에서 아래로 읽으면 "무엇인지 → 무엇을 할 수 있는지 → 받기" 순서로 흐른다. 34개가 같은 틀을 쓰고, 앱마다 분류 색으로 포인트를 준다.

```text
┌──────────────────────────────────────────────────────────┐
│ [로고] icodebroker   ← 모든 프로그램          한국어 | English │
├──────────────────────────────────────────────────────────┤
│  [큰 아이콘]  BigEdit                     [무료] [편집·문서] │
│  코드도 메모도, 가볍게 열고 편하게 고치세요   (tagline)       │
│  [⬇ 무료 다운로드 · 58MB]   v1.0.0 · Windows 10/11 64비트     │
├──────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────┐        │
│  │            큰 스크린샷 (16:10)                │        │
│  └──────────────────────────────────────────────┘        │
├──────────────────────────────────────────────────────────┤
│  소개 단락 (intro, 2~3문장)                                │
├──────────────────────────────────────────────────────────┤
│  이런 걸 할 수 있어요                                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                  │
│  │ 기능 제목 │ │ 기능 제목 │ │ 기능 제목 │  (features 3~6개) │
│  │ 짧은 설명 │ │          │ │          │                  │
│  └──────────┘ └──────────┘ └──────────┘                  │
├──────────────────────────────────────────────────────────┤
│  이럴 때 쓰세요  ✓ … ✓ … ✓ …   (uses, 있을 때만)           │
├──────────────────────────────────────────────────────────┤
│  시작하기  ① zip 받기 → ② 압축 풀기 → ③ exe 실행            │
│           (SmartScreen 경고가 뜨면 → 도움말)               │
├──────────────────────────────────────────────────────────┤
│  [⬇ 무료 다운로드] 한 번 더                                 │
│  ▸ 자세한 정보 (접어 둠): 파일 이름·크기·SHA-256·확인 명령,  │
│    설정 저장 위치, 지우는 법, 제3자 라이선스                 │
├──────────────────────────────────────────────────────────┤
│  다른 프로그램도 둘러보세요  [같은 분류 앱 카드 3개]          │
├──────────────────────────────────────────────────────────┤
│  무료 사용 · 무보증 · 재배포 금지 · 라이선스                 │
└──────────────────────────────────────────────────────────┘
```

- 다운로드 버튼은 맨 위와 아래 두 곳에 둔다.
- SHA-256 같은 기술 정보는 `<details>`로 접어 두어 일반 사용자가 겁먹지 않게 한다.
- 맨 아래 "다른 프로그램"은 같은 분류에서 최대 3개를 보여 준다(Liquid로 `apps.yml` 필터).
- `<title>`과 `og:` 태그는 앱 이름과 tagline으로 채워 링크를 공유할 때 미리 보기가 잘 나오게 한다.

### 빈 스크린샷 이미지

- `assets/screenshots/placeholder.png`, 1280×800(16:10)
- 연한 미색 바탕에 창 모양 테두리, 가운데 그림 아이콘과 "스크린샷 준비 중 · Screenshot coming soon"
- 만드는 방법: PowerShell + System.Drawing으로 그려서 저장(다시 만들 수 있게 `tools/New-Placeholder.ps1`로 둔다)
- 나중에 바꾸는 법: `assets/screenshots/BigEdit.png`(1280×800 권장)를 넣고 `apps.yml`의 `screenshot:`에 파일 이름을 적는다

## 7. 업로드 스크립트 `tools/Publish-Apps.ps1`

Windows PowerShell 5.1 호환. 인자 `-App <이름>`(하나만), `-WhatIf`(업로드 없이 출력만), `-Force`(같은 태그가 있으면 덮어쓰기).

앱마다:

1. `D:\UTILITY\<폴더>\publish\<앱>.exe`를 찾는다. 제외 목록(BigChat, BigVideoStream, BigPlayer)은 건너뛴다.
2. csproj `<Version>`에서 버전을 읽는다.
3. 임시 폴더에 exe와 README.txt(+ BigRemote는 FreeRDP 라이선스)를 모아 zip을 만든다.
4. zip SHA-256을 계산한다.
5. `gh release create <앱>-v<버전> <zip> --title ... --notes ...`. 같은 태그가 있으면 건너뛰고, `-Force`면 `gh release upload --clobber`로 덮어쓴다.
6. `_data/apps.yml`에서 version·zip·size·sha256·url·released만 갱신한다. 사람이 쓴 summary·features·screenshot은 건드리지 않는다.
7. 상세 페이지 파일(`apps/<앱>.html`, `en/apps/<앱>.html`)이 없으면 만든다.
8. `.ico`를 128px PNG로 바꿔 `assets/icons/`에 둔다(없을 때만).

## 8. 진행 단계

0. ~~gh 로그인~~ → 완료(2026-11-18, `gh auth status` 확인)
1. 개인 정보 검사: 34개 exe에서 내 PC 경로·IP·계정 문자열을 찾는다(`strings` 방식) → 검증: 걸린 것이 없거나 사용자가 괜찮다고 확인
2. 제3자 라이선스 수집: 앱별 `PackageReference`와 내장 파일(글꼴, FreeRDP, ONNX 등)의 라이선스 목록 → 검증: 라이선스 페이지 초안에 빠진 패키지가 없는지 csproj와 대조
3. 스크립트 작성, `-WhatIf` 실행 → 검증: 34개, 제외 3개, zip에 exe·README.txt(BigRemote는 +1)만 들어 있는지 출력으로 확인
4. 시험 업로드(BigCalculator 하나) → 검증: 다운로드 주소에서 `curl -L`로 받아 SHA-256이 같은지, 풀어서 exe가 실행되는지
5. 빈 스크린샷 이미지와 아이콘 PNG 만들기 → 검증: 이미지 열어서 확인
6. 사이트 틀(레이아웃, CSS, ko/en 첫 화면, BigEdit 소개 페이지 하나) → 검증: 로컬 Jekyll(또는 푸시 후)에서 데스크톱·휴대폰 폭 스크린샷, 라이트·다크 모두, 사용자 디자인 확인
7. 34개 전체 업로드, `apps.yml`·소개 페이지 파일 생성 → 검증: 모든 `url`이 302→200인지 스크립트로 확인
8. 앱별 소개 글(summary·tagline·intro·features·uses) ko/en 작성: 메모와 소스(메뉴·기능 코드)를 근거로 초안 → 검증: 사용자 검토(몇 개씩 나눠서)
9. 라이선스·도움말 페이지 → 검증: 내부 링크 깨짐 검사, ko/en 짝이 다 있는지
10. 커밋·푸시·배포 확인 → 검증: 실제 사이트에서 카드 34개, ko/en 전환, 다운로드 버튼 몇 개 실제로 받기

이후 업데이트: 앱 `publish.ps1` → `Publish-Apps.ps1 -App BigEdit -Force`(또는 버전을 올리고 새 태그) → 커밋·푸시

## 9. 주의할 점

- **서명 안 된 exe**: SmartScreen "Windows의 PC 보호" 경고가 뜬다. 코드 서명은 유료라 범위에서 빼고, 도움말 페이지와 SHA-256으로 대신한다. 백신이 잘못 진단할 수 있다.
- **제3자 라이선스**: FreeRDP(Apache 2.0, BigRemote), 나눔고딕코딩·Latin Modern Math 등 글꼴(OFL), .NET 런타임(MIT), NuGet 패키지들. "무료·무보증"은 내 코드에 대한 조건이고, 제3자 부분은 각 라이선스를 따른다고 고지한다.
- **BigPlayer**: 다시 넣으려면 libmpv(GPL) 때문에 소스 공개가 필요하다.
- **용량**: Releases는 파일당 2GiB, 전체 제한 없음. 사이트 저장소에는 이미지와 텍스트만 들어가 수 MB 수준이다.

## 10. 확인할 것

없음. 2026-11-18 답변(재배포 금지, 사이트 이름 icodebroker, 상세 페이지는 앱 소개 페이지)을 2·4·6절에 반영했다.
