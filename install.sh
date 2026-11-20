#!/usr/bin/env bash
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_DIR:-$HOME/.codex}"
MARK_BEGIN="<!-- seungyong-ai-kit:begin -->"
MARK_END="<!-- seungyong-ai-kit:end -->"

DRY_RUN=0
WITH_RULES=1
WITH_WRITING=0
WITH_CODEX=0
UNINSTALL=0

usage() {
  cat <<EOF
사용법: ./install.sh [옵션]

기본 동작
  skills/, agents/, commands/를 ${CLAUDE_DIR} 아래에 심볼릭 링크로 연결하고
  rules/*.md를 ${CLAUDE_DIR}/CLAUDE.md에 @import 블록으로 추가합니다.
  같은 이름이 이미 있으면 덮어쓰지 않고 건너뜁니다.

옵션
  --dry-run       실제로 바꾸지 않고 할 일만 출력
  --no-rules      CLAUDE.md에 rules import를 넣지 않음
  --with-writing  writing/*.md도 CLAUDE.md import에 추가
  --codex         rules/*.md 내용을 ${CODEX_DIR}/AGENTS.md에 블록으로 복사
  --uninstall     이 저장소를 가리키는 링크와 추가한 블록을 제거
  -h, --help      도움말
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-rules) WITH_RULES=0 ;;
    --with-writing) WITH_WRITING=1 ;;
    --codex) WITH_CODEX=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "알 수 없는 옵션: $arg" >&2; usage; exit 1 ;;
  esac
done

LINKED=()
SKIPPED=()
REMOVED=()

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

resolve() {
  local path="$1"
  if [ -L "$path" ]; then
    local target
    target="$(readlink "$path")"
    case "$target" in
      /*) echo "${target%/}" ;;
      *) echo "$(cd "$(dirname "$path")" && cd "$(dirname "$target")" && pwd)/$(basename "$target")" ;;
    esac
  fi
}

link_item() {
  local source="${1%/}"
  local dest_dir="$2"
  local dest="$dest_dir/$(basename "$source")"

  if [ -L "$dest" ] && [ "$(resolve "$dest")" = "$source" ]; then
    SKIPPED+=("$dest (이미 연결됨)")
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    SKIPPED+=("$dest (같은 이름이 이미 있음, 건너뜀)")
    return
  fi
  run ln -s "$source" "$dest"
  LINKED+=("$dest")
}

unlink_items() {
  local dest_dir="$1"
  [ -d "$dest_dir" ] || return 0
  local entry
  for entry in "$dest_dir"/*; do
    [ -L "$entry" ] || continue
    case "$(resolve "$entry")" in
      "$KIT"/*)
        run rm "$entry"
        REMOVED+=("$entry")
        ;;
    esac
  done
}

strip_block() {
  local file="$1"
  [ -f "$file" ] || return 0
  grep -qF "$MARK_BEGIN" "$file" || return 0
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] $file 에서 seungyong-ai-kit 블록 제거"
    return 0
  fi
  local tmp
  tmp="$(mktemp)"
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip { lines[++n] = $0; if ($0 != "") last = n }
    END { for (i = 1; i <= last; i++) print lines[i] }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
  REMOVED+=("$file (블록)")
}

write_block() {
  local file="$1"
  local body="$2"
  strip_block "$file"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] $file 에 블록 추가:"
    printf '%s\n' "$body" | sed 's/^/    /'
    return 0
  fi
  mkdir -p "$(dirname "$file")"
  {
    [ -s "$file" ] && echo ""
    echo "$MARK_BEGIN"
    printf '%s\n' "$body"
    echo "$MARK_END"
  } >> "$file"
  LINKED+=("$file (블록)")
}

claude_import_block() {
  local lines=""
  local f
  if [ "$WITH_RULES" -eq 1 ]; then
    for f in "$KIT"/rules/*.md; do lines+="@$f"$'\n'; done
  fi
  if [ "$WITH_WRITING" -eq 1 ]; then
    for f in "$KIT"/writing/*.md; do lines+="@$f"$'\n'; done
  fi
  printf '%s' "${lines%$'\n'}"
}

codex_block() {
  local f
  local first=1
  for f in "$KIT"/rules/*.md; do
    [ "$first" -eq 1 ] || printf '\n'
    first=0
    cat "$f"
  done
}

print_summary() {
  local item
  if [ "${#LINKED[@]}" -gt 0 ]; then
    echo "연결/추가:"
    for item in "${LINKED[@]}"; do echo "  + $item"; done
  fi
  if [ "${#REMOVED[@]}" -gt 0 ]; then
    echo "제거:"
    for item in "${REMOVED[@]}"; do echo "  - $item"; done
  fi
  if [ "${#SKIPPED[@]}" -gt 0 ]; then
    echo "건너뜀:"
    for item in "${SKIPPED[@]}"; do echo "  = $item"; done
  fi
}

if [ "$UNINSTALL" -eq 1 ]; then
  unlink_items "$CLAUDE_DIR/skills"
  unlink_items "$CLAUDE_DIR/agents"
  unlink_items "$CLAUDE_DIR/commands"
  strip_block "$CLAUDE_DIR/CLAUDE.md"
  strip_block "$CODEX_DIR/AGENTS.md"
  print_summary
  exit 0
fi

run mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands"

for item in "$KIT"/skills/*/; do link_item "$item" "$CLAUDE_DIR/skills"; done
for item in "$KIT"/agents/*.md; do link_item "$item" "$CLAUDE_DIR/agents"; done
for item in "$KIT"/commands/*.md; do link_item "$item" "$CLAUDE_DIR/commands"; done

if [ "$WITH_RULES" -eq 1 ] || [ "$WITH_WRITING" -eq 1 ]; then
  write_block "$CLAUDE_DIR/CLAUDE.md" "$(claude_import_block)"
fi

if [ "$WITH_CODEX" -eq 1 ]; then
  write_block "$CODEX_DIR/AGENTS.md" "$(codex_block)"
fi

print_summary

cat <<EOF

다음 단계
  - hook은 자동으로 연결하지 않습니다. hooks/settings.example.json을 보고 settings.json에 직접 추가하세요.
  - placeholder({PROJECT_ROOT}, {BASE_BRANCH}, <OBSIDIAN_VAULT> 등)를 채우세요.
  - 건너뛴 항목이 있으면 docs/SETUP.md의 "이름 충돌" 절을 보세요.
EOF
