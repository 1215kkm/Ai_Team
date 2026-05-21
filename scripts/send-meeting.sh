#!/usr/bin/env bash
# send-meeting.sh — 강팀 회의록을 텔레그램으로 전송
#
# 사용:
#   bash send-meeting.sh [회의 폴더 경로]
#     - 인자가 없으면 ./.ai-team/meetings/ 안에서 *가장 최근* 폴더 자동 선택
#
# 전송 내용 (개인 봇 → 본인 DM):
#   1) 텍스트 요약  (마감 턴의 SUMMARY 마커 안 내용)
#   2) meeting.html  (sendDocument)
#   3) mockup.html   (sendDocument · 있을 때만)
#   4) meeting/mockup PNG 스크린샷 (헤드리스 크롬 있을 때만)
#
# 설정:
#   ~/.claude/team-config/telegram.env 에서 TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID 로드.
#   처음이면 `bash setup-telegram.sh` 실행해서 생성.
#
# 옵션:
#   --dry-run    실제 전송 없이 어떤 내용 갈지만 출력
#   --no-png     PNG 스크린샷 생략
#   --no-html    HTML 파일 첨부 생략
#   --quiet      성공 메시지 최소화

set -euo pipefail

DRY_RUN=0
NO_PNG=0
NO_HTML=0
QUIET=0
MEETING_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --no-png)  NO_PNG=1; shift ;;
    --no-html) NO_HTML=1; shift ;;
    --quiet)   QUIET=1; shift ;;
    -h|--help)
      sed -n '2,/^set -e/p' "$0" | sed 's/^# \{0,1\}//;/^set -e/d'
      exit 0 ;;
    *) MEETING_DIR="$1"; shift ;;
  esac
done

log() { [[ $QUIET -eq 0 ]] && echo "$@" >&2 || true; }
err() { echo "오류: $*" >&2; exit 1; }

# ---------- 1. 회의 폴더 찾기 ----------
if [[ -z "$MEETING_DIR" ]]; then
  if [[ ! -d ".ai-team/meetings" ]]; then
    err "회의 폴더가 없습니다. 인자로 경로를 주거나 .ai-team/meetings/ 가 있는 위치에서 실행해주세요."
  fi
  MEETING_DIR=$(find .ai-team/meetings -mindepth 1 -maxdepth 1 -type d -print0 \
    | xargs -0 ls -dt 2>/dev/null | head -1 || true)
  [[ -z "$MEETING_DIR" ]] && err ".ai-team/meetings/ 안에 회의 폴더가 없습니다."
fi

[[ -d "$MEETING_DIR" ]] || err "회의 폴더 없음: $MEETING_DIR"
MEETING_HTML="$MEETING_DIR/meeting.html"
MOCKUP_HTML="$MEETING_DIR/mockup.html"
[[ -f "$MEETING_HTML" ]] || err "meeting.html 없음: $MEETING_HTML"

# 회의 제목 추출
TITLE=$(grep -m1 -oE '<title>[^<]*</title>' "$MEETING_HTML" | sed 's/<[^>]*>//g' || echo "강팀 회의")
DATE=$(grep -m1 -oE '날짜: [0-9-]+' "$MEETING_HTML" | sed 's/날짜: //' || date +%F)

log "회의: $TITLE ($DATE)"
log "폴더: $MEETING_DIR"

# ---------- 2. 텔레그램 설정 로드 ----------
CONFIG="$HOME/.claude/team-config/telegram.env"
if [[ $DRY_RUN -eq 0 ]]; then
  [[ -f "$CONFIG" ]] || err "$CONFIG 가 없습니다. 먼저 'bash setup-telegram.sh' 실행해주세요."
  # shellcheck disable=SC1090
  source "$CONFIG"
  [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]] || err "TELEGRAM_BOT_TOKEN 누락"
  [[ -n "${TELEGRAM_CHAT_ID:-}"   ]] || err "TELEGRAM_CHAT_ID 누락"
fi

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN:-DRY}"

# ---------- 3. 요약 추출 ----------
extract_summary() {
  awk '
    /<!-- SUMMARY_START -->/ { flag=1; next }
    /<!-- SUMMARY_END -->/   { flag=0 }
    flag
  ' "$MEETING_HTML" \
    | sed -e 's/<br[^>]*>/\n/gi' -e 's/<\/li>/\n/gi' -e 's/<li[^>]*>/• /gi' \
          -e 's/<\/h[1-6]>/\n/gi' -e 's/<h[1-6][^>]*>/\n■ /gi' \
          -e 's/<[^>]*>//g' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | awk 'NF || prev { print; prev=NF } NF==0 { prev=0 }'
}

SUMMARY=$(extract_summary)
if [[ -z "$SUMMARY" ]]; then
  # 폴백: 본문 첫 줄 + "(요약 마커 비어있음)"
  SUMMARY="(SUMMARY 마커가 비어있습니다. 강팀장이 마감 턴에 채워주세요.)"
fi

# 텔레그램 메시지 본문 (HTML 모드)
HEADER="<b>🎯 강팀 회의록</b>
<i>${TITLE}</i>
<code>${DATE}</code>
"
MESSAGE="${HEADER}
${SUMMARY}"

# 4096자 컷
if [[ ${#MESSAGE} -gt 3900 ]]; then
  MESSAGE="${MESSAGE:0:3900}
...(잘림 — 전체는 첨부된 meeting.html 참조)"
fi

# ---------- 4. PNG 스크린샷 (선택) ----------
SCREEN_MEETING=""
SCREEN_MOCKUP=""
render_png() {
  local src="$1" out="$2"
  local browser=""
  for cand in chromium chromium-browser google-chrome chrome "google-chrome-stable"; do
    if command -v "$cand" >/dev/null 2>&1; then browser="$cand"; break; fi
  done
  [[ -z "$browser" ]] && return 1

  "$browser" --headless --disable-gpu --no-sandbox \
             --hide-scrollbars --virtual-time-budget=3000 \
             --window-size=1200,1800 \
             --screenshot="$out" \
             "file://$(cd "$(dirname "$src")" && pwd)/$(basename "$src")" \
             >/dev/null 2>&1 || return 1
  [[ -s "$out" ]]
}

if [[ $NO_PNG -eq 0 ]]; then
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT

  if render_png "$MEETING_HTML" "$TMP_DIR/meeting.png"; then
    SCREEN_MEETING="$TMP_DIR/meeting.png"
    log "✓ meeting.png 렌더링"
  else
    log "⚠ 헤드리스 크롬 없음 또는 렌더링 실패 — PNG 스킵"
  fi

  if [[ -f "$MOCKUP_HTML" ]]; then
    if render_png "$MOCKUP_HTML" "$TMP_DIR/mockup.png"; then
      SCREEN_MOCKUP="$TMP_DIR/mockup.png"
      log "✓ mockup.png 렌더링"
    fi
  fi
fi

# ---------- 5. Dry run 출력 ----------
if [[ $DRY_RUN -eq 1 ]]; then
  echo "── DRY RUN ──"
  echo "[메시지]"
  echo "$MESSAGE"
  echo
  echo "[첨부]"
  [[ $NO_HTML -eq 0 ]] && echo "  - $MEETING_HTML"
  [[ $NO_HTML -eq 0 && -f "$MOCKUP_HTML" ]] && echo "  - $MOCKUP_HTML"
  [[ -n "$SCREEN_MEETING" ]] && echo "  - $SCREEN_MEETING (PNG)"
  [[ -n "$SCREEN_MOCKUP"  ]] && echo "  - $SCREEN_MOCKUP (PNG)"
  exit 0
fi

# ---------- 6. 텔레그램 전송 ----------
tg_call() {
  local method="$1"; shift
  local resp
  resp=$(curl -sS --max-time 30 -X POST "$API/$method" "$@")
  if ! echo "$resp" | grep -q '"ok":true'; then
    echo "텔레그램 $method 실패:" >&2
    echo "$resp" >&2
    return 1
  fi
}

# 회의 식별자 = 폴더명 (callback_data에 박아 polling에서 매칭)
MEETING_ID=$(basename "$MEETING_DIR")
# 4096byte 컷이 콜백 데이터에 영향 없도록 ID는 짧게
SHORT_ID=$(echo -n "$MEETING_ID" | head -c 60)

# inline keyboard JSON
# 버튼: 진행 / 보류 / 🧠 결정 저장 / 🧠 전체 저장 / 회의 다시
KEYBOARD=$(cat <<JSON
{"inline_keyboard":[
  [
    {"text":"✅ 진행","callback_data":"go:${SHORT_ID}"},
    {"text":"⏸ 보류","callback_data":"pause:${SHORT_ID}"}
  ],
  [
    {"text":"🧠 결정만 강팀에 저장","callback_data":"learn-d:${SHORT_ID}"},
    {"text":"🧠 전체 저장","callback_data":"learn-all:${SHORT_ID}"}
  ],
  [
    {"text":"🔄 회의 다시","callback_data":"redo:${SHORT_ID}"}
  ]
]}
JSON
)

log "→ 요약 텍스트 + 버튼 전송"
tg_call sendMessage \
  --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${MESSAGE}" \
  --data-urlencode "parse_mode=HTML" \
  --data-urlencode "disable_web_page_preview=true" \
  --data-urlencode "reply_markup=${KEYBOARD}"

if [[ $NO_HTML -eq 0 ]]; then
  log "→ meeting.html 전송"
  tg_call sendDocument \
    -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "document=@${MEETING_HTML};type=text/html" \
    -F "caption=meeting.html"

  if [[ -f "$MOCKUP_HTML" ]]; then
    # mockup.html이 거의 비어있으면 (템플릿 그대로면) 스킵
    if grep -q "SCREENS_START" "$MOCKUP_HTML" && \
       ! awk '/<!-- SCREENS_START -->/,/<!-- SCREENS_END -->/' "$MOCKUP_HTML" \
         | grep -q 'class="screen"'; then
      log "  mockup.html 비어있음 — 스킵"
    else
      log "→ mockup.html 전송"
      tg_call sendDocument \
        -F "chat_id=${TELEGRAM_CHAT_ID}" \
        -F "document=@${MOCKUP_HTML};type=text/html" \
        -F "caption=mockup.html"
    fi
  fi
fi

if [[ -n "$SCREEN_MEETING" ]]; then
  log "→ meeting PNG 전송"
  tg_call sendPhoto \
    -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "photo=@${SCREEN_MEETING}" \
    -F "caption=📋 회의 흐름"
fi

if [[ -n "$SCREEN_MOCKUP" ]]; then
  log "→ mockup PNG 전송"
  tg_call sendPhoto \
    -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "photo=@${SCREEN_MOCKUP}" \
    -F "caption=🎨 화면 목업"
fi

log "✓ 전송 완료 — 텔레그램에서 확인하세요."
