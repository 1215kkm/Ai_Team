<!-- 강팀 트리거 룰 (BEGIN) — install-global.sh 가 ~/.claude/CLAUDE.md 에 자동 삽입 -->
## 강팀 불러오기 트리거

사용자가 다음 중 하나를 말하면, 메인 클로드는 답변 시늉 대신 *바로* `pull-team.sh` 를 실행한다:

- "강팀 불러와" / "강팀 가져와" / "강팀 박아"
- "Ai_Team에서 강팀 ..." / "1215kkm/Ai_Team에서 ..."
- `/강팀불러오기`

실행 순서 (병렬 확인 후 본체 1번):

```bash
# 1) 본체 실행 (로컬 → 전역 → 원격 순서로 fallback)
if [[ -f scripts/pull-team.sh ]]; then
  bash scripts/pull-team.sh
elif [[ -f ~/.claude/bin/pull-team.sh ]]; then
  bash ~/.claude/bin/pull-team.sh
else
  curl -fsSL https://raw.githubusercontent.com/1215kkm/Ai_Team/main/scripts/pull-team.sh | bash
fi
```

설치 후 사용자에게 한 줄만 보고: "강팀 도착 — `/회의시작` 가능".

## 강팀 발언 규칙

`.claude/agents/` 가 있는 레포에서, 강팀 닉네임(강팀장·강디1·강디2·강개발·강체크·강홍보·강감시·아뱅·강사장)으로 발언해야 할 때 메인 클로드가 시늉하지 말고 *반드시* `Agent` 툴로 해당 서브에이전트(`pm`, `ux-designer`, `ui-designer`, `developer`, `qa`, `marketer`, `security`, `abang`, `ceo-advisor`)를 호출한다. 시늉만 하면 회의록·글로벌 브레인이 오염된다.
<!-- 강팀 트리거 룰 (END) -->
