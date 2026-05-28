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

# 프로젝트명 추출 — 한 텔레그램 채팅으로 여러 프로젝트 회의록이 들어와도 한눈에 구분되도록
PROJECT_NAME=""
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_NAME="$(basename "$(git rev-parse --show-toplevel)")"
  REMOTE_URL="$(git config --get remote.origin.url 2>/dev/null || true)"
  if [[ -n "$REMOTE_URL" ]]; then
    REPO_SLUG="$(echo "$REMOTE_URL" | sed -E 's#.*[:/]([^/]+/[^/.]+)(\.git)?$#\1#')"
    [[ -n "$REPO_SLUG" && "$REPO_SLUG" != "$REMOTE_URL" ]] && PROJECT_NAME="$REPO_SLUG"
  fi
fi
[[ -z "$PROJECT_NAME" ]] && PROJECT_NAME="$(basename "$(pwd)")"

log "프로젝트: $PROJECT_NAME"
log "회의: $TITLE ($DATE)"
log "폴더: $MEETING_DIR"

# ---------- 2. 텔레그램 설정 로드 ----------
CONFIG="$HOME/.claude/team-config/telegram.env"
if [[ $DRY_RUN -eq 0 ]]; then
  # 우선순위: 1) 환경변수, 2) ~/.claude/team-config/telegram.env
  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    if [[ -f "$CONFIG" ]]; then
      # shellcheck disable=SC1090
      source "$CONFIG"
    fi
  fi
  [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]] || err "TELEGRAM_BOT_TOKEN 없음. 'bash setup-telegram.sh' 실행하거나 환경변수로 주입."
  [[ -n "${TELEGRAM_CHAT_ID:-}"   ]] || err "TELEGRAM_CHAT_ID 없음. 'bash setup-telegram.sh' 실행하거나 환경변수로 주입."
fi

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN:-DRY}"

# ---------- 3. 요약·흐름·사인오프 추출 (2026-05-28 갱신, 3통 구조) ----------
# 마커 블록 본문을 HTML 그대로 추출 (텔레그램 parse_mode=HTML 호환 태그만 유지).
extract_block() {
  local start="$1" end="$2"
  awk -v s="$start" -v e="$end" '
    $0 ~ s { flag=1; next }
    $0 ~ e { flag=0 }
    flag
  ' "$MEETING_HTML" \
    | sed -e 's/<br[^>]*>/\n/gi' -e 's/<\/li>/\n/gi' -e 's/<li[^>]*>/• /gi' \
          -e 's/<\/h[1-6]>/\n/gi' -e 's/<h[1-6][^>]*>/\n■ /gi' \
          -e 's/<[^>]*>//g' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | awk 'NF || prev { print; prev=NF } NF==0 { prev=0 }'
}

# SUMMARY 를 결정/미결정/다음액션 3섹션으로 분리 (메시지 ①·③ 분기 위해)
extract_summary_section() {
  local section="$1"   # 결정 | 미결정 | 다음 액션
  awk -v sec="$section" '
    /<!-- SUMMARY_START -->/ { in_sum=1; next }
    /<!-- SUMMARY_END -->/   { in_sum=0 }
    in_sum && /<h3>/ {
      gsub(/<[^>]*>/,"",$0); current=$0; gsub(/^[[:space:]]+|[[:space:]]+$/,"",current);
      capture=(index(current, sec)>0) ? 1 : 0; next
    }
    in_sum && capture { print }
  ' "$MEETING_HTML" \
    | sed -e 's/<br[^>]*>/\n/gi' -e 's/<\/li>/\n/gi' -e 's/<li[^>]*>/• /gi' \
          -e 's/<[^>]*>//g' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | awk 'NF || prev { print; prev=NF } NF==0 { prev=0 }'
}

DECISIONS=$(extract_summary_section "결정")
PENDING=$(extract_summary_section "미결정")
ACTIONS=$(extract_summary_section "다음 액션")
NARRATIVE=$(extract_block "<!-- NARRATIVE_START -->" "<!-- NARRATIVE_END -->")

# 폴백: NARRATIVE 마커 비어있으면 TURNS 에서 각 멤버 첫 div 의 who+첫 문장 자동 추출
if [[ -z "$NARRATIVE" ]]; then
  NARRATIVE=$(awk '
    /<!-- TURNS_START -->/ { in_turns=1; next }
    /<!-- TURNS_END -->/   { in_turns=0 }
    in_turns
  ' "$MEETING_HTML" \
    | tr -d '\n' \
    | sed -E 's/<div class="turn [^"]*">/\n@@TURN@@/g' \
    | sed -E 's/<div class="who">([^<]*<[^>]+>[^<]*<\/[^>]+>[^<]*)<\/div>.*?<div class="bubble">/ \1 — /' \
    | sed -E 's/<\/?[^>]+>//g' \
    | awk '/^@@TURN@@/ { print substr($0, 9, 220) "..." }' \
    | head -10)
  [[ -z "$NARRATIVE" ]] && NARRATIVE="(NARRATIVE 마커 비어있음 · TURNS 추출 실패 — 강팀장이 NARRATIVE 블록 채워주세요)"
fi

# 헤더 (메시지 ① 첫 줄)
HEADER="<b>📦 ${PROJECT_NAME}</b>
🎯 <b>강팀 회의록</b> · <i>${TITLE}</i>
<code>${DATE}</code>"

# ── 메시지 ① 결정 풀이 (결정 + 다음 액션)
MSG1="${HEADER}

<b>📋 결정</b>
${DECISIONS:-(결정 비어있음)}

<b>📌 다음 액션</b>
${ACTIONS:-(다음 액션 비어있음)}"

# ── 메시지 ② 9명 발언 흐름
MSG2="<b>🎬 9명 발언 흐름</b>

${NARRATIVE}"

# ── 메시지 ③ CEO 사인오프 + HTML 안내
MSG3="<b>🤝 CEO 사인오프 (예/아니오 한 마디로)</b>

${PENDING:-(미결정 항목 없음 — CEO 결정 대기 사항 없음)}

<b>📎 첨부</b>
• meeting.html (9명 원본 발언 + 표·SVG·Mermaid)
• 폰: 첨부 다운로드 → 브라우저 열기
• 답하는 법: 채팅창에 \"A예 B예 ...\" 한 줄"

# 4096자 컷 (각 메시지)
for var in MSG1 MSG2 MSG3; do
  cur="${!var}"
  if [[ ${#cur} -gt 3900 ]]; then
    eval "$var=\"\${cur:0:3900}
...(잘림 — 자세히는 첨부 HTML)\""
  fi
done

# 호환성 — 기존 코드가 $MESSAGE 참조하면 MSG1 사용
MESSAGE="$MSG1"

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

# Windows Git Bash curl은 비ASCII argv를 CP949로 망가뜨려 텔레그램이 UTF-8 거부함.
# JSON 본문을 파일로 직렬화해 --data-binary 로 보내면 우회 가능.
# 환경에 node가 있으면 JSON 경로, 아니면 기존 argv 경로 (mac/linux 회귀 방지).
HAVE_NODE=0
command -v node >/dev/null 2>&1 && HAVE_NODE=1

# UTF-8 안전 sendMessage. 인자 1: 메시지 본문. 인자 2: keyboard JSON 또는 빈 문자열.
tg_send_message() {
  local text="$1"
  local keyboard="${2:-}"
  if [[ $HAVE_NODE -eq 1 ]]; then
    local json_tmp
    json_tmp=$(mktemp)
    TG_CHAT="$TELEGRAM_CHAT_ID" TG_TEXT="$text" TG_KB="$keyboard" \
      node -e '
        const fs=require("fs");
        const payload={
          chat_id: process.env.TG_CHAT,
          text: process.env.TG_TEXT,
          parse_mode: "HTML",
          disable_web_page_preview: true
        };
        if (process.env.TG_KB && process.env.TG_KB.length > 0) {
          payload.reply_markup = JSON.parse(process.env.TG_KB);
        }
        fs.writeFileSync(1, JSON.stringify(payload));
      ' > "$json_tmp"
    local resp
    resp=$(curl -sS --max-time 30 -X POST "$API/sendMessage" \
      -H "Content-Type: application/json; charset=utf-8" \
      --data-binary "@$json_tmp")
    rm -f "$json_tmp"
    if ! echo "$resp" | grep -q '"ok":true'; then
      echo "텔레그램 sendMessage 실패:" >&2
      echo "$resp" >&2
      return 1
    fi
  else
    local args=(
      --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}"
      --data-urlencode "text=${text}"
      --data-urlencode "parse_mode=HTML"
      --data-urlencode "disable_web_page_preview=true"
    )
    [[ -n "$keyboard" ]] && args+=(--data-urlencode "reply_markup=${keyboard}")
    tg_call sendMessage "${args[@]}"
  fi
}

# 한국어/이모지 캡션을 UTF-8 임시 파일에 써서 -F "caption=<file" 로 넘기는 헬퍼.
# 사용: cap_arg=$(tg_caption_file "📋 회의 흐름"); tg_call sendPhoto ... -F "caption=<${cap_arg}"
tg_caption_file() {
  local f
  f=$(mktemp)
  printf '%s' "$1" > "$f"
  echo "$f"
}

# 회의 식별자 = 폴더명 (callback_data에 박아 polling에서 매칭)
MEETING_ID=$(basename "$MEETING_DIR")
# callback_data 는 64바이트 한도 + ASCII 권장. 한국어 슬러그면 UTF-8 경계 깨지므로
# 짧은 해시(앞 12자)로 안전화. polling 쪽은 해시-→폴더 매핑 별도 보관 필요.
SHORT_ID=$(echo -n "$MEETING_ID" | sha1sum | cut -c1-12)

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

log "→ 메시지 ① 결정 풀이"
tg_send_message "$MSG1" ""
log "→ 메시지 ② 9명 발언 흐름"
tg_send_message "$MSG2" ""
log "→ 메시지 ③ CEO 사인오프 + HTML 안내 (인라인 키보드)"
tg_send_message "$MSG3" "$KEYBOARD"

# 한국어 파일 경로는 Windows curl 의 -F "document=@..." 가 깨뜨림 (exit 26).
# cp 자체도 한국어 argv 깨먹어서 cat 으로 읽어 ASCII 경로로 쓴다 (Windows 회귀 가드).
copy_to_ascii_tmp() {
  local src="$1" basename_dst="$2"
  local dst="/tmp/${basename_dst}"
  if [[ ! -f "$src" ]]; then
    echo "  [copy_to_ascii_tmp] src not found: $src" >&2
    return 1
  fi
  if ! cat "$src" > "$dst"; then
    echo "  [copy_to_ascii_tmp] cat failed src=$src dst=$dst" >&2
    return 1
  fi
  if [[ ! -s "$dst" ]]; then
    echo "  [copy_to_ascii_tmp] dst empty: $dst" >&2
    return 1
  fi
  echo "$dst"
}

if [[ $NO_HTML -eq 0 ]]; then
  log "→ meeting.html 전송"
  # Windows curl 의 ";type=text/html" 옵션이 exit 26 유발 → 빼고 보내면 텔레그램이 확장자로 MIME 추론.
  # copy_to_ascii_tmp 는 안전망으로 유지 (다른 한국어 글자 조합에서 재발 시 폴백).
  tg_call sendDocument \
    -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "document=@${MEETING_HTML}" \
    -F "caption=meeting.html"

  if [[ -f "$MOCKUP_HTML" ]]; then
    if grep -q "SCREENS_START" "$MOCKUP_HTML" && \
       ! awk '/<!-- SCREENS_START -->/,/<!-- SCREENS_END -->/' "$MOCKUP_HTML" \
         | grep -q 'class="screen"'; then
      log "  mockup.html 비어있음 — 스킵"
    else
      log "→ mockup.html 전송"
      tg_call sendDocument \
        -F "chat_id=${TELEGRAM_CHAT_ID}" \
        -F "document=@${MOCKUP_HTML}" \
        -F "caption=mockup.html"
    fi
  fi
fi

if [[ -n "$SCREEN_MEETING" ]]; then
  log "→ meeting PNG 전송"
  cap_meeting=$(tg_caption_file "📋 회의 흐름")
  tg_call sendPhoto \
    -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "photo=@${SCREEN_MEETING}" \
    -F "caption=<${cap_meeting}"
  rm -f "$cap_meeting"
fi

if [[ -n "$SCREEN_MOCKUP" ]]; then
  log "→ mockup PNG 전송"
  cap_mockup=$(tg_caption_file "🎨 화면 목업")
  tg_call sendPhoto \
    -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "photo=@${SCREEN_MOCKUP}" \
    -F "caption=<${cap_mockup}"
  rm -f "$cap_mockup"
fi

log "✓ 전송 완료 — 텔레그램에서 확인하세요."
