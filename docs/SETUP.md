# 설치와 주의사항

새 컴퓨터나 다른 작업 환경에서 이 저장소를 AI 에이전트에 연결할 때 보는 문서입니다.

## 빠른 설치

```bash
git clone https://github.com/dltmddyd321/seungyong-ai-kit.git ~/seungyong-ai-kit
cd ~/seungyong-ai-kit
./install.sh --dry-run
./install.sh
```

`--dry-run`으로 먼저 무엇이 바뀌는지 확인한 뒤 실행합니다.

| 옵션 | 동작 |
|---|---|
| (없음) | `skills/`, `commands/`를 `~/.claude/` 아래에 심볼릭 링크로 연결하고, `rules/*.md`를 `~/.claude/CLAUDE.md`에 `@import` 블록으로 추가 |
| `--dry-run` | 실제로 바꾸지 않고 할 일만 출력 |
| `--no-rules` | `CLAUDE.md`에 rules import를 넣지 않음 |
| `--with-writing` | `writing/*.md`도 import에 추가 |
| `--with-android` | `android/skills/`, `android/agents/`도 링크하고 `android/rules/*.md`도 import(`--codex`와 함께 쓰면 Codex 블록에도 포함) |
| `--codex` | `rules/*.md` 내용을 `~/.codex/AGENTS.md`에 블록으로 복사 |
| `--uninstall` | 이 저장소를 가리키는 링크와 추가한 블록을 제거 |

`CLAUDE_DIR`, `CODEX_DIR` 환경변수로 설치 위치를 바꿀 수 있습니다.

`CLAUDE.md`와 `AGENTS.md`에 넣는 내용은 `<!-- seungyong-ai-kit:begin -->`과 `<!-- seungyong-ai-kit:end -->` 사이에만 들어갑니다. 여러 번 실행해도 블록은 하나로 유지되고, 블록 밖의 기존 내용은 건드리지 않습니다.

## 주의사항

### 1. 받기만 해서는 적용되지 않는다

- **스킬, 에이전트, 명령어:** `~/.claude/` 아래에 연결해야 인식됩니다. `install.sh`가 심볼릭 링크로 연결하므로, 이후에는 `git pull`만 하면 갱신됩니다. 저장소 폴더를 옮기거나 지우면 링크가 끊깁니다.
- **`rules/`, `writing/`:** 문서라서 `CLAUDE.md`에서 불러와야 에이전트가 읽습니다. `install.sh`가 `rules/`는 기본으로, `writing/`은 `--with-writing`일 때 import 블록에 넣습니다.
- **hook:** 자동으로 연결하지 않습니다. `hooks/settings.example.json`을 보고 `~/.claude/settings.json`이나 프로젝트의 `.claude/settings.json`에 직접 추가합니다. 경로는 이 저장소의 실제 위치로 바꿉니다.

### 2. 이름 충돌

같은 이름의 스킬, 에이전트, 명령어가 이미 있으면 `install.sh`는 덮어쓰지 않고 건너뜁니다. 건너뛴 항목은 실행 결과의 "건너뜀"에 나옵니다.

- 기존 것이 특정 프로젝트에 맞춘 원본이라면 그대로 두는 편이 낫습니다. 이 저장소의 버전은 일반화하면서 프로젝트 고유 정보를 뺀 것이라 덜 구체적입니다.
- 이 저장소 버전을 쓰려면 기존 것을 다른 곳으로 옮긴 뒤 `install.sh`를 다시 실행합니다.
- 플러그인(everything-claude-code 등)이 설치한 같은 이름의 에이전트나 명령어가 있으면 어느 쪽이 쓰일지 헷갈립니다. 이름이 겹치면 한쪽만 남깁니다.

### 3. 설치 후 채워야 할 값

| 값 | 위치 |
|---|---|
| `{PROJECT_ROOT}`, `<Variant>` | `android/skills`, `android/agents` |
| `{BASE_BRANCH}` | `commands/pr.md`, `commands/learn.md` |
| `<OBSIDIAN_VAULT>` | `skills/dev-memo` |
| `<WIKI_DIR>` | `skills/meeting-wiki` |
| `<PACKAGE_NAME>`, `<QUOTA_PROJECT>` | `android/skills/play-vitals-query` |
| `config.env` | `android/skills/translation-sheet/scripts/` (`config.example.env`를 복사해서 작성) |

채우지 않으면 해당 스킬을 쓸 때 에이전트가 값을 묻거나 실패합니다. 링크로 연결한 파일을 직접 고치면 저장소 파일이 바뀌므로, 환경마다 값이 다르면 프로젝트의 `AGENTS.md`에 값을 적고 스킬은 그대로 두는 편이 낫습니다.

`config.env`에는 실제 시트 ID와 메일 주소가 들어가므로 커밋하지 않습니다. `.gitignore`에 이미 들어 있습니다.

### 4. Codex 등 다른 에이전트

- Codex는 `@import`를 지원하지 않습니다. `--codex`는 `rules/*.md` 내용을 `~/.codex/AGENTS.md`에 그대로 복사합니다. 규칙을 고친 뒤에는 `./install.sh --codex`를 다시 실행해야 반영됩니다.
- `~/.codex/AGENTS.md`에 플러그인이 넣은 내용이 이미 있으면 그 뒤에 블록이 붙습니다. 두 규칙이 부딪히면 어느 쪽을 따를지 정해 한쪽을 정리합니다.
- `~/.claude/skills/`는 Claude Code 전용 위치입니다. 다른 에이전트에서는 그 에이전트의 스킬 로딩 방식에 맞춰 따로 연결합니다.

### 5. 개인 작업 방식이 들어 있다

- `rules/working-style.md`에는 "한국어로 답변", "빌드는 요청할 때만", "주석 금지" 같은 개인 작업 방식이 들어 있습니다. 본인 작업 환경에서는 그대로 쓰고, 다른 사람과 같이 쓰는 환경이라면 `--no-rules`로 설치한 뒤 필요한 파일만 골라 import합니다.
- 프로젝트의 `AGENTS.md`에 같은 주제의 규칙이 있으면 프로젝트 규칙이 우선입니다.

### 6. 프로젝트 종류

- 루트의 `rules/`, `skills/`, `commands/`는 특정 언어나 플랫폼에 묶이지 않은 범용 항목입니다.
- `android/`는 Android/Kotlin 프로젝트에서만 의미가 있어 기본 설치에서 빠집니다. 필요한 환경에서만 `--with-android`로 설치합니다. 나중에 다른 플랫폼 전용 항목이 생기면 같은 방식으로 폴더를 나눕니다.

## 제거

```bash
./install.sh --uninstall
```

이 저장소를 가리키는 심볼릭 링크와 `CLAUDE.md`, `AGENTS.md`에 넣은 블록만 지웁니다. 건너뛴(원래 있던) 파일은 건드리지 않습니다.
