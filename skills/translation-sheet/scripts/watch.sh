#!/bin/zsh
set -euo pipefail

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
DIR="${TW_HOME:-${0:A:h}}"
[ -f "$DIR/config.env" ] && source "$DIR/config.env"
: "${TW_SHEET_FILE_ID:?config.env에 TW_SHEET_FILE_ID를 설정하세요}"
: "${TW_RECIPIENT:?config.env에 TW_RECIPIENT를 설정하세요}"
: "${TW_RES_DIR:?config.env에 TW_RES_DIR를 설정하세요}"
: "${TW_TAB:?config.env에 TW_TAB를 설정하세요}"
: "${TW_LOCALES:?config.env에 TW_LOCALES를 설정하세요}"
export TW_RES_DIR TW_TAB TW_LOCALES
FILE_ID="$TW_SHEET_FILE_ID"
RECIPIENT="$TW_RECIPIENT"
XLSX_MIME="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

mkdir -p "$DIR/state" "$DIR/inbox"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

json_field() { python3 -I -c "import json,sys;d=json.load(sys.stdin);print(d['data']$1)"; }

modified=$(composio execute GOOGLEDRIVE_GET_FILE_METADATA \
  -d "{\"fileId\": \"$FILE_ID\", \"fields\": \"modifiedTime\"}" | json_field "['modifiedTime']")
last=$(cat "$DIR/state/last_modified" 2>/dev/null || true)
[ "$modified" = "$last" ] && exit 0
echo "[$(date '+%F %T')] sheet modified: $modified"

url=$(composio execute GOOGLEDRIVE_EXPORT_GOOGLE_WORKSPACE_FILE \
  -d "{\"fileId\": \"$FILE_ID\", \"mimeType\": \"$XLSX_MIME\"}" | json_field "['file']['s3url']")
curl -fsSL "$url" -o "$work/sheet.xlsx"

out="$DIR/inbox/$(date '+%Y-%m-%d_%H%M').md"
set +e
python3 -I "$DIR/diff_sheet.py" "$work/sheet.xlsx" "$DIR/state/snapshot.json" "$out"
rc=$?
set -e
echo "$modified" > "$DIR/state/last_modified"
[ $rc -ne 0 ] && exit 0

summary=$(grep -m1 '새로 생기거나 바뀐 행' "$out")
python3 -I -c '
import json, sys
path, to, subject, body_path = sys.argv[1:5]
json.dump({"recipient_email": to, "subject": subject, "body": open(body_path, encoding="utf-8").read(), "is_html": False},
          open(path, "w", encoding="utf-8"), ensure_ascii=False)
' "$work/send.json" "$RECIPIENT" "[번역 시트 변경] $summary" "$out"
composio execute GMAIL_SEND_EMAIL -d @"$work/send.json" >/dev/null
osascript -e "display notification \"$summary\" with title \"번역 시트 변경\" subtitle \"$(basename "$out")\" sound name \"Glass\""
echo "notified: $out"
