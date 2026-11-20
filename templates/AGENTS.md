# {PROJECT_NAME} ({REPO_NAME})
{한 줄 설명: 어떤 앱의 Android 클라이언트인지}

## 1. Core Rules
- **Language & Output**: Always respond in clear, natural Korean. Ensure all Korean responses are fully formed and grammatically correct UTF-8 strings without token corruption.
  - **`AskUserQuestion`은 한글 깨짐이 반복적으로 발생한 도구다.** 특히 `preview` 필드처럼 길거나, 화살표(→)/불릿(-)/줄바꿈이 섞인 복잡한 한글 문자열을 넣을 때 깨짐이 재현됐다.
  - 질문 내용이 짧고 단순한 경우에만 `AskUserQuestion`을 쓰고, `option`/`preview`에 넣을 한글은 최대한 짧고 특수문자 없이 작성한다.
  - 질문 내용이 길거나, 여러 항목을 나열하거나, 표/화살표/줄바꿈이 필요하면 **`AskUserQuestion` 대신 일반 채팅 텍스트로 직접 질문**한다.
  - 깨짐이 한 번 발생했다면 같은 요청을 반복하지 말고, 일반 텍스트로 다시 작성해서 전달한다.
- **No unsolicited comments (STRICT)**: Never add code comments — not even a short "why" explanation, not even a KDoc block on a function you write or edit — unless the user explicitly asks for one in that specific request. This applies to both new code and edits to existing code. If you already wrote one out of habit, delete it before finishing the turn.
- **Accuracy first**: Correctness over speed. Always read the actual code before making judgments.
- **No guessing**: Never say "probably" or "likely". Base answers on code verification.
- **Check impact scope**: Use `grep`/`Find Usages` aggressively. Watch for Java/Kotlin cross-references.
- **One change at a time**: Fix one problem, then verify before moving on.
- **Preserve existing behavior**: Existing working behavior is product policy. If a refactor changes it (run count, repetition, reset conditions, thread, error handling), don't make the change — apply the minimal fix instead, or list the differences and get approval first.
- **Stability first**: Consider cache/list memory optimization, OOM prevention, and thread safety.
- **Self-verification loop**: Edit → `./gradlew compile{Variant}Kotlin` → `./gradlew lint{Variant}` → `./gradlew test{Variant}UnitTest`. Run only when the user asks. **On failure, stop and report** (failed step, location, expected vs actual, suspected cause, proposed fix) and wait for approval before changing code; after an approved fix, rerun from the first step. Never loop fix → rerun on your own.

## 2. Stack & Environment
- **Package**: `com.example.app` / applicationId: `com.example.app`
- **Build**: minSdk {N} / targetSdk {N} / compileSdk {N} / Java {N}
- **Languages**: Kotlin {version}, Java (legacy mixed 여부)
- **Frameworks**:
  - **DI**: {Hilt 등}
  - **DB**: {Primary / Secondary, 스키마 버전}
  - **Network**: {Retrofit / OkHttp 등}
  - **Async**: {Coroutines / RxJava 등}
  - **UI**: {ViewBinding / Jetpack Compose}
  - **기타**: {날짜/시간, 이벤트 버스 등}

## 3. Architecture & Domain Concepts
- **Init (`{Application 클래스}`)**: {초기화, 마이그레이션 담당}
- **API (`{네트워크 베이스 클래스}`)**: {인증, 재시도 등 공통 처리}
- **DB**: {어떤 데이터가 어느 DB에 있는지, 스레드 제약}
- **Sync**: {동기화 단위와 담당 모듈}
- **{핵심 모델}**: {설명}

## 4. Key Directories & Files (watch out for large files)
- `activity/`: UI screens (`{큰 파일}` {크기}KB)
- `adapter/`: List adapters
- `db/`: DB logic and migrations
- `feature/`: Core data domains
- `api/`: API tasks
- `util/`: Utilities

## 5. Coding Style
- **Naming**: No numbered variable names (`option0`, `temp1`). Use clear, descriptive English names.
- **Immutability**: Minimize `var`. Prefer `val`.
- **Null Safety**: Never use force-unwrap (`!!`). Use `?.let` or `?:`. Watch for `null` returns from Java calls.
- **Deduplication**: Extract duplicate UI into `Composable`, duplicate logic into inner functions.
- **Async Scope**: No `GlobalScope`. Use `Dispatchers.IO` for IO, `Dispatchers.Main` or `lifecycleScope` for UI.
- **Logging**: {프로젝트에서 실제로 쓰는 로거}
- **Text size**: {`android:textSize` 단위 관례: sp 또는 dp}

## 6. 하네스: 스킬 구성

### Android Dev (코드 변경 전반)

**목표:** Explorer → Implementer → BuildVerifier → Reviewer 파이프라인으로 안전하고 검증된 코드 변경 수행

**트리거:** 기능 추가, 버그 수정, 코드 구현, UI 수정 등 코드 변경 작업 시 `android-dev` 스킬을 사용하라. 단순 코드 설명/질문은 직접 응답 가능.
파일 1~2개/10줄 안팎처럼 규모가 작으면 스킬의 "작업 규모 판단" 기준에 따라 파이프라인 없이 직접 처리한다.

**도메인 작업:** {결제 등 도메인 참조 스킬이 있으면 여기에 적는다}

### Android Test (테스트 파이프라인)

**목표:** 사람이 정한 요구사항 → 승인된 시나리오 → 테스트(Red) → 구현(Green) 순서로 테스트를 붙이고, 실패할 때마다 멈춰서 보고·승인 후 처음부터 재실행하는 루프

**트리거:** "테스트 작성해줘", "테스트 붙여줘", "TDD로 진행해줘", "회귀 테스트 추가" 등 테스트 작업 요청 시 `android-test` 스킬을 사용하라. 테스트 작성은 `android-test-writer` 에이전트가 승인된 시나리오만으로 수행한다.
구현에 맞춰 테스트를 쓰지 않고, 같은 behavior를 검증하는 테스트를 여러 개 만들지 않는다. 테스트를 통과시키려고 테스트를 고치는 수정은 별도로 승인받는다.

### Translation Sheet (다국어 문자열 반영)

**트리거:** 사용자가 번역 표를 붙여넣으며 "다국어 처리", "번역 반영", "strings 정리" 등으로 요청할 때 `translation-sheet` 스킬을 사용하라.
시트 원문을 임의로 교정하지 않고, 대응 키가 애매하면 반드시 사용자에게 확인한다.

### Figma Implement (Figma 디자인 반영)

**트리거:** Figma 노드 링크나 디자인 스크린샷을 주며 "이 디자인 구현해줘", "Figma 반영해줘" 등으로 요청할 때 `figma-implement` 스킬을 사용하라.
간격/폰트/색상은 추측 없이 Figma 스펙과 정확히 대조하고, 공유 drawable/색상은 임의로 고치지 않는다.

> 브랜치와 무관하게 쓰는 스킬은 개인 전역(`~/.claude/skills/`)에 두면 브랜치마다 스킬 파일을 따로 유지하고 머지할 필요가 없다. 이 위치는 Claude Code 전용이므로 Codex 등 다른 에이전트는 그 에이전트의 스킬/규칙 로딩 방식에 맞춰 따로 참조해야 한다.

**변경 이력:**
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| YYYY-MM-DD | 초기 구성 (`android-dev` 파이프라인) | 전체 코드 변경 | 신규 하네스 구축 |

## 7. 이슈 커밋 규칙

`.claude/current_issue.md`가 존재하면 해당 파일의 `commit_prefix` 값을 **커밋 메시지 첫 줄로 고정**하라.

커밋 메시지 형식:
```
{commit_prefix}

{변경 내용 요약 (선택)}
```

예시:
```
https://issues.example.com/browse/PROJ-123 설정 화면 상단 배지 제거

- 설정 화면 상단 배지 제거
```

`/issue` 명령으로 이슈를 시작하면 자동 설정된다. 새 이슈로 전환할 때 `/issue`를 다시 실행하면 덮어써진다.

## 8. 빌드·배포 전 난독화 점검 제안
사용자가 빌드 업로드·배포(버전 빌드 커밋, 테스트 배포, 스토어 업로드 등)를 하려는 게 보이면, **직접 실행하지 말고** 먼저 `release-obfuscation-check` 스킬의 점검(R8 통과, Gson·리플렉션 직렬화 클래스 보호 여부, `mapping.txt` 확인, release 빌드 핵심 화면 확인)을 하라고 제안한다. 사용자가 요청하면 그때 수행한다.
