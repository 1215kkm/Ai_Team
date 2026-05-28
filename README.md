# 강팀 (Ai_Team)

**강팀** — 9명짜리 한국어 AI 팀. Claude Code의 서브 에이전트로 동작.

> **CEO (사용자) · 🧭 강사장 · 🎯 강팀장 · 🧪 강디1 · 🎨 강디2 · ⚙️ 강개발 · 🔍 강체크 · 📣 강홍보 · 🛡️ 강감시 · 💡 아뱅**

전체 구조와 역할 관계는 [`docs/role-architecture.md`](./docs/role-architecture.md) 참조.

---

## 가장 빠른 사용법 — 다른 레포에서 "강팀 불러와"

이미 한 번 강팀을 설치한 PC라면 (또는 클로드 웹 세션에서) 어느 레포든:

```
강팀 불러와
```

라고 채팅에 치거나 `/강팀불러오기` 슬래시 커맨드를 쓰면 끝. 강팀이 그 레포에 박힘.
원격에서 처음 받을 때 (전혀 깔린 게 없을 때) 한 줄:

```bash
curl -fsSL https://raw.githubusercontent.com/1215kkm/Ai_Team/main/scripts/pull-team.sh | bash
```

---

## 두 가지 정식 사용법

### 방법 A — 전역 설치 (모든 레포에서 자동 사용)

자기 PC에 한 번만 깔아두면, 그 PC에서 켜는 *모든* Claude Code 세션이 이 팀을 호출 가능.

**Windows (PowerShell)**
```powershell
git clone https://github.com/1215kkm/Ai_Team.git
cd Ai_Team
pwsh ./scripts/install-global.ps1            # 처음 설치
pwsh ./scripts/install-global.ps1 -Force     # 묻지 않고 덮어쓰기 (업데이트)
```

**macOS / Linux / Git Bash**
```bash
git clone https://github.com/1215kkm/Ai_Team.git
cd Ai_Team
bash ./scripts/install-global.sh            # 처음 설치
bash ./scripts/install-global.sh --force    # 묻지 않고 덮어쓰기 (업데이트)
```

설치되는 위치:
- `~/.claude/agents/` — 9개 에이전트 정의
- `~/.claude/knowledge/` — 아뱅 심리 카탈로그·UI 디자인 시스템

업데이트는 이 레포를 `git pull` 받고 스크립트 다시 실행하면 끝.

### 방법 B — 새 프로젝트 시작할 때 템플릿으로 클론

각 프로젝트마다 *팀 정의를 같이 가지고 가고 싶을 때* (프로젝트별 커스터마이즈가 들어갈 가능성 있을 때).

GitHub에서 **"Use this template"** 버튼 → 새 레포 생성 → 그 레포에 `.claude/`가 같이 복사됨.

> 템플릿 활성화는 한 번만 하면 됨: GitHub 레포 페이지 → **Settings** → **General** → 맨 위 **"Template repository"** 체크박스 ON. (이 토글은 GitHub 웹에서 사용자가 직접 켜야 함 — API 권한 밖.)

### A + B 같이 쓸 때 우선순위

Claude Code는 **프로젝트 `.claude/` 가 전역 `~/.claude/` 보다 우선**. 따라서:

- 평소 — 전역(A) 정의가 작동
- 프로젝트가 템플릿(B)에서 갈라져 나왔거나 `.claude/`를 따로 둠 — 그 프로젝트 안에서는 *프로젝트별 정의가 이김*

전역은 *공통 정체성*, 프로젝트는 *그 프로젝트 고유 페르소나·디자인 토큰·도메인 지식* 두는 식.

---

## 회의 워크플로우 (다른 레포에서도 동일)

강팀은 **HTML 회의록**으로 일한다. 브라우저에서 *대화 흐름과 화면을 같이* 본다.

```bash
# 회의 시작 (강팀장이)
bash ~/.claude/bin/start-meeting.sh "이벤트 페이지 디자인"
# → 현재 프로젝트의 .ai-team/meetings/2025-05-21-이벤트-페이지-디자인/ 폴더 생성
#   ├ meeting.html  ← 브라우저로 열어두면 회의 진행 실시간 확인
#   └ mockup.html   ← 강디2가 회의 마지막에 화면 채움
```

회의 흐름:
1. 강팀장이 첫 턴에 **안건·참석자·진행 순서** 적음
2. 각 멤버가 호출되면 자기 색·아이콘으로 **말 + 시각**(SVG·표·Mermaid·코드) 한 턴씩 append
3. *디자인/화면 안건이 있었으면* 강디2가 마지막에 **`mockup.html`에 모든 화면을 한 페이지 grid로** 빠르게 채움
4. `meeting.html` 하단 iframe이 자동으로 mockup을 띄움 — 전원이 같은 화면을 봄
5. 강팀장이 `<!-- SUMMARY_START -->` 블록에 **결정 / 미결정 / 다음 액션** 채움
6. **모든 참석자가 한 줄씩** 코멘트
7. **텔레그램 자동 전송** — `bash ~/.claude/bin/send-meeting.sh` → 요약 + meeting.html + mockup.html + PNG 스크린샷이 본인 DM 으로

### 텔레그램 연동 (최초 1회만)

```bash
bash ~/.claude/bin/setup-telegram.sh
# 1) @BotFather에서 봇 만든 토큰 입력
# 2) 봇과 한 번 대화 후 chat_id 자동 감지
# 3) ~/.claude/team-config/telegram.env 에 저장 (chmod 600, 깃에 안 들어감)
```

이후 어디서든 회의 끝나면 자동으로 본인 텔레그램으로 회의록이 들어옵니다. PNG 스크린샷은 헤드리스 Chrome/Chromium 이 깔려 있어야 렌더됨 (없어도 텍스트+HTML 은 그대로 전송).

---

## 성장 — 다른 레포에서 배운 걸 다음 프로젝트로 가져가기

강팀의 *뇌*는 `~/.claude/knowledge/team-memory/` (전역, 모든 레포 공유).

**프로젝트 종료 의례:**
1. 강팀장이 `~/.claude/templates/lesson.md` 복사 → 회고 작성 (멤버별 한 줄 + Keep/Drop/Try)
2. *글로벌 브레인으로 옮길 항목*에 체크
3. 체크된 항목만 이 `Ai_Team` 레포 `.claude/knowledge/team-memory/`로 **PR**
4. 머지 후 다른 PC에서 `install-global` 재실행 → 학습된 강팀이 다음 프로젝트에서도 작동

> 이 의례를 빼먹으면 강팀은 다음 프로젝트에서 원점. 강사장·강팀장이 매번 환기.

---

## 디자인 베이스 — 번호 매겨진 스타일 카탈로그

강팀의 모든 시각 산출물은 *카탈로그에 등록된 디자인 스타일 한 개* 위에서 굴러간다.
어느 스타일을 쓰는지는 `.claude/knowledge/ui-designer/styles/active.txt` 한 줄 (예: `1`) 이 정한다.

- **기본 활성 스타일**: **#1 — Crowny Class** (보라→분홍 그라데이션, Pretendard, 16px 본문, radius 10/16). 전체 명세: [`.claude/knowledge/ui-designer/styles/01-crowny-class.md`](./.claude/knowledge/ui-designer/styles/01-crowny-class.md)
- **카탈로그**: [`.claude/knowledge/ui-designer/styles/README.md`](./.claude/knowledge/ui-designer/styles/README.md) — 등록된 스타일 표 + 새 스타일 등록 방법
- **전환**: "디자인 스타일 N번 적용해" (자연어) 또는 `/디자인스타일 N` — 강디2가 `active.txt` + 프로젝트의 `styles/tokens.css` 를 한 트랜잭션에 갱신
- **임의 HEX·새 토큰 즉석 사용 금지** — 활성 스타일 파일에 *먼저 추가* 후 사용
- **아뱅이 들어와도 스타일 토큰은 깨지 않는다** — 차별화는 토큰을 *깊이 활용* (그라데이션 각도·그림자 레이어·마이크로 인터랙션)
- 앞으로 #2, #3, ... 신규 스타일을 추가하며 *프로젝트별로* 활성 스타일 번호만 골라 쓰는 방향

## 강팀 발전 — 다른 레포에서 본체로 학습 PR

다른 레포에서 회의·작업하다 *재사용 가능한 패턴*을 발견하면:

```
강팀 업데이트
```
또는 `/강팀업데이트` → `scripts/promote-to-team.sh` 가 자동으로:
1. 가장 최근 회의 요약 추출
2. 이 `Ai_Team` 레포에 `learn/<프로젝트>-<날짜>-<슬러그>` 브랜치로 PR 자동 생성
3. PR URL CEO 에게 보고 → CEO 가 PR 페이지에서 "재사용 가능 패턴 3개 체크박스" 채운 뒤 머지
4. 머지 후 다른 PC·세션에서 `pull-team.sh` 다시 돌리면 *학습된 강팀*이 따라옴 (SessionStart 훅이 SHA 비교해 알림)

---

## 폴더 구조

```
.
├── .claude/
│   ├── agents/              # 9개 에이전트 정의
│   │   ├── abang.md         # 💡 아뱅
│   │   ├── ceo-advisor.md   # 🧭 강사장
│   │   ├── pm.md            # 🎯 강팀장
│   │   ├── ux-designer.md   # 🧪 강디1
│   │   ├── ui-designer.md   # 🎨 강디2
│   │   ├── developer.md     # ⚙️ 강개발
│   │   ├── qa.md            # 🔍 강체크
│   │   ├── marketer.md      # 📣 강홍보
│   │   └── security.md      # 🛡️ 강감시
│   └── knowledge/           # 에이전트가 참조하는 지식 베이스
│       ├── abang/           # 심리 레버 카탈로그·사례
│       ├── ui-designer/     # 디자인 시스템
│       └── team-memory/     # 프로젝트 회고가 쌓이는 전역 브레인
│           ├── lessons/     #   Keep / Drop / Try
│           ├── decisions/   #   큰 결정과 근거
│           ├── patterns/    #   반복 사용 작업 패턴
│           └── domain/      #   도메인별 지식
├── docs/
│   └── role-architecture.md # 팀 구조 다이어그램
├── templates/               # 회의·목업·회고 템플릿
│   ├── meeting.html         #   회의록 (HTML 채팅)
│   ├── mockup.html          #   화면 목업 (한 페이지 grid)
│   └── lesson.md            #   프로젝트 회고 시트
├── scripts/
│   ├── install-global.{ps1,sh}  # 전역 설치 (~/.claude/)
│   └── start-meeting.{ps1,sh}   # 새 회의 폴더 생성
├── CLAUDE.md                # 강팀 정체성·회의 프로토콜·성장 의례
└── README.md
```
