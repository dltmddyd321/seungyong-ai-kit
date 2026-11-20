# Android Dev 하네스

Android/Kotlin 프로젝트에서 AI 에이전트가 코드를 바꾸고 테스트를 붙이는 방식을 고정한 구성이다. 스킬 2개(오케스트레이터), 서브에이전트 5개, 보조 스킬과 명령, 훅으로 이뤄진다.

설계의 중심은 두 가지다.

- 큰 변경만 파이프라인으로 돌리고, 작은 변경은 직접 처리한다.
- 빌드나 테스트가 실패하면 에이전트가 혼자 고치고 다시 돌리지 않는다. 멈추고, 보고하고, 승인을 기다린다.

## 구성 요소

| 종류 | 파일 | 역할 |
|---|---|---|
| 스킬 | `skills/android-dev/SKILL.md` | 코드 변경 오케스트레이터. 규모 판단 후 직접 처리 또는 4단계 파이프라인 |
| 스킬 | `skills/android-test/SKILL.md` | 테스트 오케스트레이터. 요구사항 → 시나리오 승인 → Red → Green |
| 에이전트 | `agents/android-explorer.md` | 관련 코드와 수정 지점 탐색 |
| 에이전트 | `agents/android-implementer.md` | 탐색 결과로 구현 |
| 에이전트 | `agents/android-build-verifier.md` | 컴파일 → lint → 단위 테스트. 실패 시 고치지 않고 보고 |
| 에이전트 | `agents/android-reviewer.md` | Critical/High/Medium 기준 리뷰 |
| 에이전트 | `agents/android-test-writer.md` | 승인된 시나리오만으로 테스트 작성. 실행하지 않음 |
| 스킬 | `skills/commit-message/SKILL.md` | 작업 끝에 커밋 메시지 텍스트 제공 |
| 스킬 | `skills/translation-sheet/SKILL.md` | 번역 시트를 `strings.xml` 로케일별로 반영 |
| 스킬 | `skills/figma-implement/SKILL.md` | Figma 스펙을 추측 없이 코드로 반영 |
| 명령 | `commands/issue.md` | 이슈 URL + 제목 → 브랜치 생성, 커밋 첫 줄 고정 |
| 명령 | `commands/pr.md` | 현재 브랜치로 PR 생성 |
| 명령 | `commands/learn.md` | 작업에서 배운 패턴을 스킬에 추가 |
| 훅 | `hooks/check-claude-agents-sync.sh` | `CLAUDE.md`/`AGENTS.md` 미러링 어긋남 감지 |
| 템플릿 | `templates/AGENTS.md`, `templates/CLAUDE.md` | 프로젝트 규칙 파일 뼈대 |

## 코드 변경 파이프라인 (`android-dev`)

```
요청
 └─ 규모 판단 (grep으로 영향 범위 확인)
     ├─ 작음 / 이미 확정된 기계적 작업 ── grep → Read → Edit → 결과 보고
     └─ 큼 / 영향 범위 불명확 / 신규 기능
          Explorer      → _workspace/01_explore.md
          Implementer   → _workspace/02_implement.md
          BuildVerifier → _workspace/03_build.md    (사용자가 검증을 요청한 경우)
          Reviewer      → _workspace/04_review.md   (치명적 위험이 의심될 때)
```

- 각 단계 산출물을 `_workspace/`에 남겨서, 부분 수정 요청이 오면 해당 에이전트만 다시 부른다. 새 작업이면 `_workspace_prev/`로 옮기고 새로 시작한다.
- 애매하면 직접 처리 쪽으로 기운다. 서브에이전트를 순차로 띄우면 단계마다 몇 분씩 걸려서, 사용자가 "너무 느리다, 오류는 내가 실기기에서 찾겠다"고 한 뒤로 기본값을 바꿨다.
- Reviewer에서 Critical이 나오면 구현으로 돌아가되 재구현은 최대 2회까지만 반복한다.

## 실패 시 멈춤 루프

BuildVerifier와 테스트 실행 루프는 같은 규칙을 따른다.

```
실행 → 실패
  └─ 멈춤. 보고서 작성
       (단계, 위치, 기대값/실제값, 추정 원인, 제안 수정, 테스트 코드 수정 여부)
  └─ 사용자 승인 대기
  └─ 승인된 수정 1건만 반영
  └─ 1단계(컴파일)부터 다시 실행
```

- 한 번의 승인은 그 수정 한 건에만 유효하다.
- 같은 원인으로 3회 연속 실패하면 수정 제안 대신 접근 자체를 다시 검토하자고 보고한다.
- 테스트를 약하게 만들어 통과시키는 수정은 따로 명시하고 승인받는다.
- 이번 작업과 무관한 기존 테스트 실패는 고치지 않고 따로 보고한다.

처음에는 BuildVerifier가 최대 5회까지 스스로 고치고 다시 돌렸다. 이 방식은 토큰을 많이 쓰고 사용자가 모르는 수정이 쌓여서, 실패마다 보고하고 승인받은 뒤 처음부터 다시 돌리는 방식으로 바꿨다.

## 테스트 파이프라인 (`android-test`)

```
Phase 1 요구사항 (사람)         → _workspace/test/{대상}/01_requirements.md
Phase 2 시나리오 초안 → 승인     → 02_scenarios.md
Phase 3 테스트 작성 (test-writer)
Phase 4 실행 루프 (Red 확인, 실패 시 멈춤) → 03_run_{N}.md
Phase 5 구현 (Green, 계획 승인 후)
Phase 6 리팩터 제안 → 최종 리뷰  → 04_summary.md
```

- 순서는 요구사항 → 시나리오 → 테스트 → 구현이다. 구현을 보고 테스트를 맞추면 요구사항이 아니라 구현을 확인하는 테스트가 된다.
- 현재 동작이 곧 요구사항이라고 가정하지 않는다. 코드에서 읽어낸 동작은 "맞는 요구사항인지" 확인받는다.
- 테스트 작성 에이전트는 대상 코드를 시그니처 확인 용도로만 읽고, 기대값은 시나리오에서 가져온다.
- 시나리오 1개에 테스트 1개. 같은 behavior를 검증하는 테스트를 여러 개 만들지 않는다.
- 대상 우선순위는 분기가 많은 순수 로직, 결제나 동기화처럼 틀리면 돈이나 데이터가 걸리는 로직, 동시성이다.

## 빌드 실행 권한

`rules/working-style.md` 7번에 따라 빌드 태스크는 사용자가 요청할 때만 돌린다. 프로젝트 `AGENTS.md`의 Self-verification loop도 "Run only when the user asks"로 적어 둔다. `android-test` 스킬은 명시적으로 호출됐을 때만 Gradle을 실행한다.

## 설치

```bash
KIT=~/path/to/this-repo
PROJECT=~/path/to/android-project

mkdir -p "$PROJECT/.claude/skills" "$PROJECT/.claude/agents" "$PROJECT/.claude/commands" "$PROJECT/.claude/hooks"
cp -r "$KIT/skills/android-dev" "$KIT/skills/android-test" "$KIT/skills/commit-message" "$PROJECT/.claude/skills/"
cp "$KIT"/agents/android-*.md "$PROJECT/.claude/agents/"
cp "$KIT"/commands/*.md "$PROJECT/.claude/commands/"
cp "$KIT/templates/AGENTS.md" "$KIT/templates/CLAUDE.md" "$PROJECT/"
```

설치 후 바꿀 것:
- 스킬과 에이전트의 `{PROJECT_ROOT}`, `<Variant>` (예: `DevDebug`)
- `commands/pr.md`, `commands/learn.md`의 `{BASE_BRANCH}`
- `AGENTS.md`의 스택, 디렉터리, 코딩 스타일 placeholder

브랜치와 무관하게 쓰는 `translation-sheet`, `figma-implement`는 개인 전역 `~/.claude/skills/`에 두는 편이 낫다.

## 하네스를 바꿀 때

`AGENTS.md` 6번 섹션 끝의 변경 이력 표에 날짜, 변경 내용, 대상, 사유를 한 줄 추가한다(`rules/agent-config.md` 2번).
