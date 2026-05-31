# 강팀 전자동 워크플로우 — 셋업 가이드

> "회의 시작해" 한 마디 → 강팀이 안건 만들어 회의 → 텔레그램 발송 → CEO가 텔레그램 버튼 한 번 → 기획·구현·테스트·배포·홍보까지 자동.

---

## 큰 그림

```
┌──────────────┐        ┌──────────────┐         ┌──────────────┐
│   CEO        │ ──→    │  Telegram    │  ←──    │  강팀         │
│   (어디서든)  │  (버튼) │  (봇 DM)      │  (전송) │  (Claude Code)│
└──────┬───────┘        └──────┬───────┘         └──────┬───────┘
       │                       │ 15min poll              │
       │                       ↓                         │
       │              ┌──────────────────┐               │
       └──────────────│  GitHub Actions  │───────────────┘
                      │  (telegram-poll) │
                      └──────────────────┘
                              │
                              ├─→ issue 생성 (team:proceed / team:meeting)
                              │   → Claude Code on the web 트리거 → 강팀이 다음 단계
                              │
                              └─→ Ai_Team 레포에 PR (team:learn)
                                  → CEO 머지 → 강팀 학습됨
```

---

## 단계 1. 텔레그램 봇 만들기 (5분)

1. 텔레그램 `@BotFather` → `/newbot` → 봇 이름·@username → **토큰 받기**
2. 그 봇에게 아무 메시지 한 번 보내기 (chat_id 잡기용)
3. 로컬에서:
   ```bash
   bash ~/.claude/bin/setup-telegram.sh
   ```
   토큰 + chat_id 자동 감지 + `~/.claude/team-config/telegram.env` 저장 + 테스트 메시지 1건

### 봇 명령어 등록 (선택)

`@BotFather` → `/setcommands` → 봇 선택 → 아래 붙여넣기:

```
회의시작 - 강팀이 안건 자동 생성해 회의 시작
진행 - 다음 단계 자동 진행
보류 - 자동 진행 일시 정지
상태 - 현재 진행 상황 조회
```

---

## 단계 2. GitHub Secrets 등록 (각 프로젝트 레포 + Ai_Team 레포)

각 레포 → Settings → Secrets and variables → Actions → **New repository secret**

| 이름 | 값 | 필수 |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | BotFather 토큰 (`123456:ABC-DEF...`) | ✅ |
| `TELEGRAM_CHAT_ID` | 본인 chat_id (정수) | ✅ |
| `AI_TEAM_TOKEN` | fine-grained PAT (아래 "학습 토큰 설정") | ⚠️ 학습 루프용 |

> ⚠️ 다른 사람 chat_id 가 봇에 메시지 보내도 폴링이 *무시*하도록 chat_id 화이트리스트 체크가 워크플로우에 박혀있음.

### 학습 토큰 설정 (다른 레포 → Ai_Team 학습 루프용)

CEO 가 다른 프로젝트 레포에서 회의 후 텔레그램 "🧠 저장" 버튼을 누르면, 그 프로젝트 레포의 GitHub Actions 가 *Ai_Team 레포에* issue 를 생성해야 합니다. 같은 owner(`1215kkm`) 라도 *Actions 의 기본 `GITHUB_TOKEN` 은 자기 레포 한정* 이라 cross-repo 쓰기엔 PAT 가 필요합니다.

1. GitHub → 본인 프로필 → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens** → **Generate new token**
2. 설정:
   - Token name: `ai-team-learning`
   - Resource owner: `1215kkm`
   - Repository access: **Only select repositories** → `Ai_Team` *만* 선택 (다른 건 X)
   - Permissions → Repository permissions:
     - **Issues: Read and write**
     - **Contents: Read-only** (메타 조회용)
3. 생성된 토큰 복사 → 각 *프로젝트 레포* 의 Secrets 에 `AI_TEAM_TOKEN` 으로 등록
4. (선택) Ai_Team 레포에도 같은 토큰 등록해두면 Ai_Team 안에서 회의해도 같은 동선

> 이 토큰이 없으면 다른 명령(`✅ 진행`, `⏸ 보류`, `/회의시작`, `/진행`)은 정상 동작하지만, 🧠 저장 버튼만 "활성화되지 않음" 안내가 텔레그램으로 옵니다.

---

## 단계 3. Claude Code 트리거 설정 (한 번만)

[code.claude.com/docs/en/claude-code-on-the-web](https://code.claude.com/docs/en/claude-code-on-the-web) → Triggers 메뉴

각 프로젝트 레포에 다음 트리거 추가:

| 트리거 | 조건 | 동작 |
|---|---|---|
| 회의 시작 | Issue labeled `team:meeting` | 새 세션 → `/회의시작 [이슈 본문에서 주제 추출]` |
| 진행 | Issue labeled `team:proceed` | 새 세션 → `/진행` |
| 보류 | Issue labeled `team:pause` | 새 세션 → state.json paused 마킹 |

`Ai_Team` 레포에도 하나:

| 트리거 | 조건 | 동작 |
|---|---|---|
| 강팀 학습 | Issue labeled `team:learn` | 새 세션 → 이슈 본문의 회의 ID로 원본 회의록 회수 → `team-memory/` PR 생성 |

---

## 단계 4. 새 프로젝트 만들 때 — 한 줄로 모든 셋업

```bash
bash ~/.claude/bin/new-project.sh "프로젝트명" --stack html
# → 인터랙티브로 GitHub 레포 생성 + 시크릿 등록까지 한 번에 물어봄 (gh CLI 있을 때)
```

자동으로 들어가는 것:
- `.claude/` (강팀 전체 정의 + slash commands)
- `templates/` (회의 템플릿)
- `scripts/` (start-meeting, send-meeting, setup-repo-secrets 등)
- `styles/tokens.css` (Crowny Class 디자인 시스템 변수 한 파일 — *프로젝트 테마 컬러*는 여기서 오버라이드)
- `.ai-team/state.json` (상태 머신 초기값)
- `.github/workflows/telegram-poll.yml` (자동 복사됨)
- `CLAUDE.md` (이 프로젝트 전용 룰)
- **GitHub Secrets 자동 등록**: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `AI_TEAM_TOKEN` (모두 `~/.claude/team-config/telegram.env` 에서 읽음)

### 이미 존재하는 레포에 시크릿 등록

```bash
cd 기존-레포
bash ~/.claude/bin/setup-repo-secrets.sh
# 또는 cwd 무관: bash ~/.claude/bin/setup-repo-secrets.sh owner/repo
```

---

## 단계 5. 사용 흐름

### 회의

CEO (어디서든):
- Claude Code 열고 `/회의시작` → 강팀이 알아서 안건 만들어 회의 진행 → 텔레그램으로 회의록 발송
- 또는 텔레그램에 "회의 시작해" → 15분 안에 GitHub Issue 생성 → Claude Code 세션 트리거 → 위와 동일

### 회의록 받기 (텔레그램)

회의 끝나면 텔레그램에 도착:
- 텍스트 요약 (결정·미결정·다음 액션)
- meeting.html (전체 회의 흐름)
- mockup.html (디자인 안건 있었을 때)
- PNG 스크린샷 (핸드폰에서 바로 훑기)
- **inline 버튼 5개**:
  - ✅ 진행
  - ⏸ 보류
  - 🧠 결정만 강팀에 저장
  - 🧠 전체 저장
  - 🔄 회의 다시

### 버튼 누르면

| 버튼 | 결과 |
|---|---|
| ✅ 진행 | 이 레포에 `team:proceed` 이슈 → Claude 세션 트리거 → 강팀이 `/진행` 프로토콜 실행 (다음 단계 자동) |
| ⏸ 보류 | `team:pause` 이슈 → state 머신 paused. CEO 가 다시 ✅ 누르기 전까지 대기 |
| 🧠 결정 저장 | **Ai_Team 레포에 issue** → 강팀장이 결정 사항만 `team-memory/` 에 마크다운으로 추출 → **PR 생성** |
| 🧠 전체 저장 | 위와 같은데 전체 회의록 |
| 🔄 회의 다시 | 같은 안건으로 회의 재진행 (다른 관점 강조) |

### 학습 → 다음 프로젝트로

CEO 가 Ai_Team 레포에서 PR 머지 → `team-memory/` 에 새 학습 항목 박힘 → 다음에 `install-global` 하거나 새 프로젝트 만들 때 그 학습이 *자동 포함*. **강팀이 매 프로젝트마다 똑똑해집니다.**

---

## 단계 6. 배포·홍보 (자격증명 준비 후)

자격증명은 `~/.claude/team-config/credentials.env` 한 파일에 (gitignored, `chmod 600`):

```bash
# 배포 (택1 또는 여러 개)
VERCEL_TOKEN="..."
CLOUDFLARE_API_TOKEN="..."
NETLIFY_AUTH_TOKEN="..."

# SecretAD (광고 자동 집행) — 이 레포는 별도: github.com/1215kkm/secretAD
SECRETAD_API_URL="https://..."
SECRETAD_API_KEY="..."
SECRETAD_DEFAULT_BUDGET=10000  # 일 예산 KRW (이 한도 안에서만 집행)
SECRETAD_MAX_BUDGET=100000     # 광고 전체 예산 상한

# 도메인
DOMAIN_REGISTRAR_API_KEY="..."  # 자동 도메인 잡을 거면
```

### 승인 게이트

다음 단계는 **반드시 텔레그램 승인**받고 진행 (state 머신의 `gates`):

- **deploy**: 첫 배포 전
- **promote**: 광고 집행 전 (돈 빠져나감)

각 게이트 도달 시 강팀장이 텔레그램으로:
```
🚀 배포 준비 완료
URL: preview.example.com
체크: ✅ 빌드 / ✅ 테스트 / ✅ 보안

[✅ 배포 진행] [⏸ 보류] [🔄 한 번 더 테스트]
```

CEO 가 ✅ 누르면 → state.json gates.deploy = "approved" → 강팀이 production 배포 → 배포 URL 텔레그램 즉시 보고.

### SecretAD 자동 홍보 (API 명세 확정 후)

아뱅가 호출:
```bash
curl -X POST "$SECRETAD_API_URL/campaigns" \
  -H "Authorization: Bearer $SECRETAD_API_KEY" \
  -d '{
    "name": "프로젝트명 런칭",
    "budget": '$SECRETAD_DEFAULT_BUDGET',
    "copy": "...(아뱅 심리 레버 적용)",
    "target_url": "https://..."
  }'
```

> 정확한 엔드포인트·필드는 SecretAD 레포 README 확정 후 아뱅 에이전트에 박을 예정.

---

## 비용

- **GitHub Actions**: 15분 cron polling = 월 96 × 30 = 2,880회 × 평균 15초 = ~12시간. *프라이빗 레포* 무료 한도 2,000분 안 → 무료.
- **Telegram Bot**: 무료.
- **Cloudflare Pages / Vercel Hobby**: 무료 (소규모).
- **도메인**: 도메인 잡을 때만 비용.
- **SecretAD 광고**: 본인 예산 안에서.

---

## 보안 / 리스크 (강체크 메모)

| 리스크 | 대응 |
|---|---|
| 텔레그램 봇 토큰 유출 | gitignored 파일 / GitHub Secrets / chmod 600 |
| 다른 사람이 봇에 명령 | chat_id 화이트리스트 (워크플로우 9~10줄 참고) |
| 자동 배포 폭주 | 배포 전 텔레그램 승인 게이트 *반드시* |
| 광고비 폭주 | `SECRETAD_DEFAULT_BUDGET` / `SECRETAD_MAX_BUDGET` 상한 + 게이트 |
| 자동 수정 무한 루프 | `/진행` 프로토콜에서 3회 실패 시 자동 정지 |
| Ai_Team 레포에 잘못된 PR 머지 | 머지 전 CEO 가 GitHub UI 에서 직접 검토 (자동 머지 X) |

---

## 트러블슈팅

- **텔레그램 명령 무응답**: GitHub Actions 탭에서 `telegram-poll` 워크플로우 로그 확인 → "ignored (chat ...)" 보이면 chat_id 시크릿 잘못 등록.
- **PNG 첨부 안 옴**: 헤드리스 Chromium 없음. `apt install chromium-browser` 또는 무시.
- **버튼이 안 보임**: 텔레그램 클라이언트 캐시. 메시지 위로 스크롤하면 보임.
- **/진행이 안 먹힘**: state.json 의 stage 가 `idle` 일 때는 회의부터 먼저. `/회의시작`.
