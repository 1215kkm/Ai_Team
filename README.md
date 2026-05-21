# 강팀 (Ai_Team)

**강팀** — 9명짜리 한국어 AI 팀. Claude Code의 서브 에이전트로 동작.

> **CEO (사용자) · 🧭 강사장 · 🎯 강팀장 · 🧪 강디1 · 🎨 강디2 · ⚙️ 강개발 · 🔍 강체크 · 📣 강홍보 · 🛡️ 강감시 · 💡 아뱅**

전체 구조와 역할 관계는 [`docs/role-architecture.md`](./docs/role-architecture.md) 참조.

---

## 두 가지 사용법

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
5. **모든 참석자가 한 줄씩** 코멘트 → 회의 종료

> 디자인/화면 안건이 없었던 회의는 4·5 단계 생략 — 강팀장이 *결정·미결정·다음 액션* 정리 턴으로 닫는다.

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

## 디자인 베이스: "엄청 심플"

강디1·강디2가 모든 산출물에 박는 룰. 자세한 건 각 에이전트 파일 참조.

- 한 화면 = 한 목표 / 분기 ≤ 2 / 단계 ≤ 3
- 색 ≤ 3 / 그림자·그라데이션 금지(기본) / 장식 0 / 타이포 스케일 3단
- 아뱅이 들어와도 *심플 베이스는 깨지 않는다* — 차별화는 카피·타이밍·심리·한 요소 깊이로

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
