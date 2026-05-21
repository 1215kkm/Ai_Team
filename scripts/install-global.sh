#!/usr/bin/env bash
# install-global.sh — Ai_Team을 전역 (~/.claude/)에 설치
# Linux / macOS / Git Bash on Windows
#
# 사용:
#   bash ./scripts/install-global.sh           # 기존 파일 있으면 확인
#   bash ./scripts/install-global.sh --force   # 묻지 않고 덮어쓰기

set -euo pipefail

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_AGENTS="$REPO_ROOT/.claude/agents"
SRC_KNOW="$REPO_ROOT/.claude/knowledge"
DST_ROOT="$HOME/.claude"
DST_AGENTS="$DST_ROOT/agents"
DST_KNOW="$DST_ROOT/knowledge"

if [[ ! -d "$SRC_AGENTS" ]]; then
  echo "에이전트 폴더를 찾지 못함: $SRC_AGENTS" >&2
  echo "레포 루트에서 실행했나요?" >&2
  exit 1
fi

echo "Ai_Team 전역 설치"
echo "  source : $REPO_ROOT"
echo "  target : $DST_ROOT"
echo

mkdir -p "$DST_AGENTS" "$DST_KNOW"

copy_tree() {
  local from="$1" to="$2" label="$3"
  while IFS= read -r -d '' file; do
    local rel="${file#$from/}"
    local target="$to/$rel"
    mkdir -p "$(dirname "$target")"

    if [[ -e "$target" && $FORCE -eq 0 ]]; then
      read -r -p "[$label] 덮어쓸까? $rel  (y/N) " ans
      if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
        echo "  스킵: $rel"
        continue
      fi
    fi
    cp "$file" "$target"
    echo "  복사: $rel"
  done < <(find "$from" -type f -print0)
}

echo "[1/2] agents 복사"
copy_tree "$SRC_AGENTS" "$DST_AGENTS" "agents"
echo
echo "[2/2] knowledge 복사"
copy_tree "$SRC_KNOW" "$DST_KNOW" "knowledge"

echo
echo "완료. 이제 어떤 레포에서든 Claude Code를 켜면 강사장·강팀장·강디1·강디2·강개발·강체크·강홍보·강감시·아뱅을 호출할 수 있음."
echo "프로젝트 .claude/ 에 같은 파일이 있으면 그쪽이 우선."
