# seungyong-ai-kit

Android 개발을 하면서 Claude Code와 Codex 같은 AI 코딩 에이전트에 쓰는 개인 규칙, 스킬, 에이전트, 하네스 모음입니다.
작업 중에 에이전트를 정정했던 내용을 규칙으로 정리했고, 각 규칙에는 왜 생겼는지(**Why**)를 같이 적었습니다.

문서는 한국어로 쓰고 기술 용어는 영어 그대로 둡니다.

## 폴더 구성

```
.
├── rules/            에이전트 작업 방식 규칙
├── writing/          기술 블로그, 지원 서류 작성 규칙
├── skills/           Claude Code 스킬 (SKILL.md)
├── agents/           Claude Code 서브에이전트 정의
├── commands/         Claude Code 슬래시 명령
├── harness/          스킬, 에이전트, 훅을 묶은 하네스 설명
├── notes/            짧은 기술 노트
├── hooks/            Claude Code 훅 스크립트와 설정 예시
└── templates/        프로젝트용 AGENTS.md / CLAUDE.md 템플릿
```

## 목차

### rules/
| 파일 | 내용 |
|---|---|
| [working-style.md](rules/working-style.md) | 한국어 응답, AskUserQuestion 한글 깨짐, 추측 금지, 주석 금지, 기존 동작 보존, 빌드는 요청 시에만, 실패 시 멈춤, 파이프라인 사용 기준, worktree, 백업 파일, 인증 URL |
| [git-commit.md](rules/git-commit.md) | 커밋 메시지 형식과 범위, 자동 커밋 예외, force push 금지 |
| [code-design.md](rules/code-design.md) | GoF "증상 → 패턴" 판단표, 공용 UI 정의, Kotlin/Android 기본 스타일 |
| [security.md](rules/security.md) | 보안 감사 제안 기준, 배포 전 난독화 점검 제안(상세는 `release-obfuscation-check` 스킬) |
| [agent-config.md](rules/agent-config.md) | AGENTS.md를 원본으로 두는 방식, 하네스 변경 이력, 정정 우선순위 |

### writing/
| 파일 | 내용 |
|---|---|
| [tech-blog.md](writing/tech-blog.md) | 회사 코드 기밀, 문체(존댓말, AI 티 제거), 결과물 중심, GIF, 스크린샷 가리기, AI 요약 필드, 발행 |
| [application-docs.md](writing/application-docs.md) | 이력서와 자기소개서의 AI 티 패턴, 관례에 안 맞는 제안 반대, 면접 노트 동기화, 면접 준비 관점 |

### skills/
| 스킬 | 내용 |
|---|---|
| [android-dev](skills/android-dev/SKILL.md) | 코드 변경 오케스트레이터. 규모 판단 후 직접 처리 또는 Explorer → Implementer → BuildVerifier → Reviewer |
| [android-test](skills/android-test/SKILL.md) | 요구사항 → 시나리오 승인 → Red → Green 테스트 파이프라인 |
| [commit-message](skills/commit-message/SKILL.md) | 미커밋 변경 전체로 커밋 메시지 텍스트 하나 제공 |
| [translation-sheet](skills/translation-sheet/SKILL.md) | 번역 시트를 `strings.xml` 로케일별로 원문 그대로 반영. `scripts/`에 시트 변경분을 스니펫으로 정리해 메일로 보내는 스크립트 |
| [figma-implement](skills/figma-implement/SKILL.md) | Figma 링크나 스크린샷을 추측 없이 Android UI로 반영 |
| [dev-memo](skills/dev-memo/SKILL.md) | 세션 작업 내용을 옵시디언 Vault에 메모로 저장 |
| [android-api-task](skills/android-api-task/SKILL.md) | 엔드포인트 + Example JSON으로 응답 모델, Retrofit 인터페이스, 호출 래퍼 생성(프로젝트 기존 패턴을 따름) |
| [android-log-capture](skills/android-log-capture/SKILL.md) | 외부 SDK 벤더 지원 요청용 adb 로그 수집, 요청 단위 자르기, 헤더와 요약, zip |
| [play-vitals-query](skills/play-vitals-query/SKILL.md) | Play Developer Reporting API로 크래시, ANR, LMK 비율 조회 |
| [release-obfuscation-check](skills/release-obfuscation-check/SKILL.md) | 배포 전 R8/Gson 난독화 점검 |

### agents/
| 에이전트 | 내용 |
|---|---|
| [android-explorer](agents/android-explorer.md) | 관련 코드와 수정 지점 탐색 |
| [android-implementer](agents/android-implementer.md) | 탐색 결과로 구현 |
| [android-build-verifier](agents/android-build-verifier.md) | 컴파일 → lint → 테스트. 실패 시 고치지 않고 보고 |
| [android-reviewer](agents/android-reviewer.md) | Critical/High/Medium 기준 코드 리뷰 |
| [android-test-writer](agents/android-test-writer.md) | 승인된 시나리오만으로 테스트 작성 |

### commands/
| 명령 | 내용 |
|---|---|
| [/issue](commands/issue.md) | 이슈 URL + 제목으로 브랜치 생성, 커밋 첫 줄 고정 |
| [/pr](commands/pr.md) | 현재 브랜치로 GitHub PR 생성 |
| [/learn](commands/learn.md) | 끝낸 작업에서 패턴을 뽑아 스킬에 추가 |

### notes/
| 파일 | 내용 |
|---|---|
| [android/api35-bottom-inset.md](notes/android/api35-bottom-inset.md) | Android 15 edge-to-edge에서 하단 inset 이중 적용과 해법(`navigationBars`, `systemWindowInsets` 둘 다 0) |
| [android/reorder-position-update.md](notes/android/reorder-position-update.md) | 순서 조정 저장 시 같은 레벨은 전부 position 갱신 |

### 그 외
| 경로 | 내용 |
|---|---|
| [harness/android-dev/README.md](harness/android-dev/README.md) | 위 스킬, 에이전트, 명령, 훅이 어떻게 맞물리는지와 실패 시 멈춤 루프 |
| [hooks/](hooks/README.md) | `CLAUDE.md`/`AGENTS.md` 동기화 감지 훅과 `settings.json` 연결 예시 |
| [templates/AGENTS.md](templates/AGENTS.md) | Android 프로젝트용 규칙 파일 템플릿 |
| [templates/CLAUDE.md](templates/CLAUDE.md) | `@AGENTS.md` 한 줄 |

## 설치

### Claude Code

개인 전역으로 쓰려면 `~/.claude/` 아래에 복사하거나 심볼릭 링크를 겁니다. 링크로 두면 이 저장소를 `git pull`할 때 같이 갱신됩니다.

```bash
KIT=~/path/to/seungyong-ai-kit

mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/commands

for s in "$KIT"/skills/*/; do ln -s "$s" ~/.claude/skills/"$(basename "$s")"; done
for a in "$KIT"/agents/*.md; do ln -s "$a" ~/.claude/agents/; done
for c in "$KIT"/commands/*.md; do ln -s "$c" ~/.claude/commands/; done
```

프로젝트 단위로 쓰려면 같은 파일을 프로젝트의 `.claude/skills`, `.claude/agents`, `.claude/commands`에 복사합니다. Android 하네스 설치 순서는 [harness/android-dev/README.md](harness/android-dev/README.md)에 있습니다.

`rules/`와 `writing/`은 문서입니다. 필요한 파일을 `~/.claude/CLAUDE.md`에서 `@` import로 불러오거나, 해당 저장소의 `AGENTS.md`에 옮겨 적어 씁니다.

```
@~/path/to/seungyong-ai-kit/rules/working-style.md
@~/path/to/seungyong-ai-kit/rules/git-commit.md
```

설치 후 바꿀 placeholder:
- `{PROJECT_ROOT}`, `<Variant>` (스킬, 에이전트)
- `{BASE_BRANCH}` (`/pr`, `/learn`)
- `<OBSIDIAN_VAULT>` (`dev-memo`)
- `<PACKAGE_NAME>`, `<QUOTA_PROJECT>` (`play-vitals-query`)
- `config.env` (`translation-sheet/scripts`, `config.example.env`를 복사해서 작성)

### Codex 등 다른 에이전트

Codex는 `CLAUDE.md`가 아니라 `AGENTS.md`를 읽습니다. 프로젝트에는 [templates/AGENTS.md](templates/AGENTS.md)를 기반으로 규칙을 쓰고, `CLAUDE.md`에는 `@AGENTS.md` 한 줄만 둡니다. `rules/`의 내용도 `AGENTS.md`에 옮겨 적으면 두 에이전트가 같은 규칙을 읽습니다. `~/.claude/skills/`는 Claude Code 전용 위치라서, 다른 에이전트에서는 그 에이전트의 스킬 로딩 방식에 맞춰 따로 연결해야 합니다.

## License

[MIT](LICENSE)
