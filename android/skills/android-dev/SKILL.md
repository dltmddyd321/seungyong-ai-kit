---
name: android-dev
description: Android/Kotlin 프로젝트 개발 오케스트레이터. 기능 추가, 버그 수정, 코드 변경, UI 수정 등 코드 변경 작업 요청 시 사용한다. 작은 변경은 직접 처리하고, 큰 변경만 Explorer → Implementer → BuildVerifier → Reviewer 파이프라인으로 수행한다. "다시 구현", "수정", "보완", "개선"처럼 후속 작업도 이 스킬로 처리한다.
---

# Android Dev Pipeline

파이프라인 구성과 배경은 `android/README.md`를 참고한다.
프로젝트 구조, 스택, 코딩 규칙은 프로젝트 루트의 `AGENTS.md`를 기준으로 한다.

## 작업 규모 판단 (파이프라인 사용 여부)

파이프라인을 태우기 전에 grep으로 영향 범위를 가늠하고 규모를 판단한다.
**애매하면 직접 처리 쪽으로 기운다.** 서브에이전트를 순차로 띄우면 단계마다 몇 분씩 걸린다.

**직접 처리 (파이프라인 생략)**
- 파일 1~2개, 10줄 안팎, 위치가 이미 명확한 경우
- 파일이 여러 개여도 사용자가 매핑이나 스펙을 이미 확정한 기계적 작업(확정된 토큰 값을 여러 뷰에 옮기기 등)
- grep → Read → Edit 순서로 직접 수행하고 결과만 보고한다. 빌드는 사용자가 요청했을 때만 돌린다.

**파이프라인 사용**
- 전체 알고리즘이 바뀌거나 파일이 크게 바뀌는 경우
- 신규 기능이나 아키텍처 변경처럼 탐색 자체가 필수인 경우
- 한 파일 안에 같은 패턴이 30곳 이상 흩어져 있거나, 여러 파일에 걸쳐 영향 범위가 불명확한 경우
- DI 그래프나 DB 스키마 연동이 바뀌는 경우

파이프라인을 쓰더라도:
- 이미 충분히 파악된 작업이면 Explorer를 생략한다.
- Reviewer는 기본 생략하고, 치명적 위험이 강하게 의심될 때만 돌린다.

## Phase 0: 컨텍스트 확인

`_workspace/` 디렉터리 존재 여부로 실행 모드를 정한다.
- `_workspace/` 없음 → **초기 실행**
- `_workspace/` 있고 부분 수정 요청 → **부분 재실행** (해당 에이전트만 재호출)
- `_workspace/` 있고 새 작업 요청 → `_workspace/`를 `_workspace_prev/`로 옮긴 뒤 **새 실행**

`_workspace/`는 작업 산출물이라 커밋 대상이 아니다. `git add`에 섞지 않는다.

## Phase 1: 탐색 (Explorer)

```
Agent(
  subagent_type: "android-explorer",
  model: "sonnet",
  prompt: "다음 작업을 위한 코드 탐색을 수행하라: {사용자 요청}

  프로젝트 루트: {PROJECT_ROOT}

  탐색 원칙:
  - grep으로 심볼/패턴을 먼저 찾고, 필요한 범위만 Read하라 (파일 전체 읽기 최소화)
  - 파일당 필요한 라인 범위만 Read (offset/limit 활용)
  - 탐색은 10분 안에 끝내라

  1. 관련 파일과 정확한 라인 번호를 찾아라
  2. 수정 지점과 영향 범위를 파악하라
  3. 결과를 _workspace/01_explore.md에 저장하라"
)
```

결제처럼 도메인 참조 스킬이 따로 있는 영역이면 Explorer에게 그 스킬도 참조하라고 알린다.

## Phase 2: 구현 (Implementer)

```
Agent(
  subagent_type: "android-implementer",
  model: "sonnet",
  prompt: "_workspace/01_explore.md를 읽고 다음 작업을 구현하라: {사용자 요청}

  프로젝트 루트: {PROJECT_ROOT}
  구현이 끝나면 변경 파일 목록을 _workspace/02_implement.md에 저장하라"
)
```

복잡한 신규 기능(새 화면, DI 모듈 추가, 복잡한 비즈니스 로직)은 model을 "opus"로 올린다.

## Phase 3: 빌드 검증 (BuildVerifier)

빌드 태스크는 사용자가 이번 작업에서 검증을 요청했을 때만 실행한다. 요청이 없으면 이 Phase를 건너뛰고, 정적 확인(import, 타입, 참조, XML)만 한 뒤 "빌드 확인 부탁드립니다"로 넘긴다.

```
Agent(
  subagent_type: "android-build-verifier",
  model: "sonnet",
  prompt: "_workspace/02_implement.md를 읽고 변경된 파일에 대한 빌드 검증을 수행하라.

  프로젝트 루트: {PROJECT_ROOT}
  검증 결과를 _workspace/03_build.md에 저장하라"
)
```

빌드가 실패하면 BuildVerifier는 고치지 않고 실패 보고서를 돌려준다. 보고서를 사용자에게 그대로 전달하고 **수정 승인을 받는다.** 승인되면 그 수정만 지시해 BuildVerifier를 다시 호출하고 1단계(컴파일)부터 다시 검증한다. 승인 없이 재호출하지 않는다.

## Phase 4: 코드 리뷰 (Reviewer)

```
Agent(
  subagent_type: "android-reviewer",
  model: "sonnet",
  prompt: "_workspace/02_implement.md의 변경 파일들을 읽고 코드 리뷰를 수행하라.

  프로젝트 루트: {PROJECT_ROOT}
  리뷰 결과를 _workspace/04_review.md에 저장하라"
)
```

Critical 이슈가 나오면 Phase 2로 돌아가 고친 뒤 Phase 3을 다시 실행한다(Phase 3 실행 조건은 동일).

## 결과 종합

끝나면 사용자에게 요약한다.
- 변경된 파일 목록
- 빌드 결과(실행한 경우)
- 리뷰 이슈(있을 경우)
- 커밋 메시지 제안(`commit-message` 스킬)

## 에러 처리

- Explorer가 관련 코드를 못 찾으면: 사용자에게 더 구체적인 정보를 요청한다.
- BuildVerifier가 실패를 보고하면: 매번 사용자에게 보고하고 수정 승인을 받는다. 같은 원인으로 3회 연속 실패하면 수정 대신 접근 자체를 다시 검토하자고 보고한다.
- Reviewer에서 Critical이 나와도 재구현은 최대 2회까지만 반복한다.

## 예시 흐름

**정상 흐름**: "설정 화면에 로그아웃 확인 다이얼로그 추가해줘"
→ Explorer가 설정 화면 파일 위치 파악 → Implementer가 다이얼로그 코드 추가 → (요청 시) BuildVerifier가 컴파일 확인 → (필요 시) Reviewer가 리뷰

**에러 흐름**: DI 컴파일 오류 발생
→ BuildVerifier가 원인과 수정안 보고 → 사용자 승인 → 생성자 파라미터 수정 → 컴파일부터 재검증 → 성공
