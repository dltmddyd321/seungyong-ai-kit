# seungyong-ai-kit

Claude Code와 Codex 같은 AI 에이전트에 쓰는 개인 규칙, 스킬, 명령 모음입니다. 어떤 프로젝트에서나 쓰는 범용 항목은 루트에, Android/Kotlin 전용 항목은 [`android/`](android/README.md)에 따로 모았습니다.
작업 중에 에이전트를 정정했던 내용을 규칙으로 정리했고, 각 규칙에는 왜 생겼는지(**Why**)를 같이 적었습니다.

문서는 한국어로 쓰고 기술 용어는 영어 그대로 둡니다.

## 폴더 구성

```
.
├── rules/            에이전트 작업 방식 규칙 (범용)
├── writing/          기술 블로그, 지원 서류 작성 규칙
├── skills/           범용 Claude Code 스킬 (SKILL.md)
├── commands/         Claude Code 슬래시 명령
├── hooks/            Claude Code 훅 스크립트와 설정 예시
├── android/          Android/Kotlin 전용 규칙, 스킬, 에이전트, 노트, 템플릿
├── docs/             설치와 주의사항
└── install.sh        설치 스크립트
```

## 목차

### rules/
| 파일 | 내용 |
|---|---|
| [working-style.md](rules/working-style.md) | 한국어 응답, AskUserQuestion 한글 깨짐, 추측 금지, 주석 금지, 기존 동작 보존, 빌드는 요청 시에만, 실패 시 멈춤, 파이프라인 사용 기준, worktree, 백업 파일, 인증 URL, 새 작업은 새 세션, 작업 루트, 개인 기기와 설정 보존, 다음 단계 선택지 생략, 결과 확인 장치 먼저, 참고 대상 수정 금지, 비싼 선택은 측정 후 |
| [git-commit.md](rules/git-commit.md) | 커밋 메시지 형식과 범위, 자동 커밋 예외, force push 금지 |
| [code-design.md](rules/code-design.md) | GoF "증상 → 패턴" 판단표, 공용 UI 정의 |
| [security.md](rules/security.md) | 보안 감사 제안 기준, 배포 전 release 전용 변환 점검 제안, 위임 중에도 멈추는 세 가지, 첫 공개 전 점검, 배포 산출물 비밀값 금지 |
| [agent-config.md](rules/agent-config.md) | AGENTS.md를 원본으로 두는 방식, 하네스 변경 이력, 정정 우선순위 |

### writing/
| 파일 | 내용 |
|---|---|
| [tech-blog.md](writing/tech-blog.md) | 회사 코드 기밀, 문체(존댓말, AI 티 제거), 결과물 중심, GIF, 스크린샷 가리기, AI 요약 필드, 발행 |
| [application-docs.md](writing/application-docs.md) | 이력서와 자기소개서의 AI 티 패턴, 관례에 안 맞는 제안 반대, 면접 노트 동기화, 면접 준비 관점 |

### skills/
| 스킬 | 내용 |
|---|---|
| [commit-message](skills/commit-message/SKILL.md) | 미커밋 변경 전체로 커밋 메시지 텍스트 하나 제공 |
| [dev-memo](skills/dev-memo/SKILL.md) | 세션 작업 내용을 옵시디언 Vault에 메모로 저장 |
| [meeting-wiki](skills/meeting-wiki/SKILL.md) | 회의록을 받아 팀 위키에 결정, 미결, 주제별로 정리 |

### commands/
| 명령 | 내용 |
|---|---|
| [/issue](commands/issue.md) | 이슈 URL + 제목으로 브랜치 생성, 커밋 첫 줄 고정 |
| [/pr](commands/pr.md) | 현재 브랜치로 GitHub PR 생성 |
| [/learn](commands/learn.md) | 끝낸 작업에서 패턴을 뽑아 스킬에 추가 |

### 그 외
| 경로 | 내용 |
|---|---|
| [hooks/](hooks/README.md) | `CLAUDE.md`/`AGENTS.md` 동기화 감지 훅과 `settings.json` 연결 예시 |

### android/
Android/Kotlin 프로젝트 전용입니다. `./install.sh --with-android`일 때만 설치됩니다. 구성과 하네스 설명은 [android/README.md](android/README.md)에 있습니다.

| 경로 | 내용 |
|---|---|
| [rules/kotlin-android.md](android/rules/kotlin-android.md) | GoF 패턴의 Kotlin/Android 관용 표현, 기본 스타일, 보안 감사 대상, 배포 전 R8 점검 |
| [skills/android-dev](android/skills/android-dev/SKILL.md) | 코드 변경 오케스트레이터. 규모 판단 후 직접 처리 또는 Explorer → Implementer → BuildVerifier → Reviewer |
| [skills/android-test](android/skills/android-test/SKILL.md) | 요구사항 → 시나리오 승인 → Red → Green 테스트 파이프라인 |
| [skills/android-api-task](android/skills/android-api-task/SKILL.md) | 엔드포인트 + Example JSON으로 응답 모델, Retrofit 인터페이스, 호출 래퍼 생성 |
| [skills/android-log-capture](android/skills/android-log-capture/SKILL.md) | 외부 SDK 벤더 지원 요청용 adb 로그 수집, 요청 단위 자르기, 헤더와 요약, zip |
| [skills/figma-implement](android/skills/figma-implement/SKILL.md) | Figma 링크나 스크린샷을 추측 없이 Android UI로 반영 |
| [skills/translation-sheet](android/skills/translation-sheet/SKILL.md) | 번역 시트를 `strings.xml` 로케일별로 원문 그대로 반영. 시트 변경분 메일 스크립트 포함 |
| [skills/play-vitals-query](android/skills/play-vitals-query/SKILL.md) | Play Developer Reporting API로 크래시, ANR, LMK 비율 조회 |
| [skills/release-obfuscation-check](android/skills/release-obfuscation-check/SKILL.md) | 배포 전 R8/Gson 난독화 점검 |
| [agents/](android/agents) | android-explorer, implementer, build-verifier, reviewer, test-writer |
| [notes/api35-bottom-inset.md](android/notes/api35-bottom-inset.md) | Android 15 edge-to-edge에서 하단 inset 이중 적용과 해법 |
| [notes/reorder-position-update.md](android/notes/reorder-position-update.md) | 순서 조정 저장 시 같은 레벨은 전부 position 갱신 |
| [templates/](android/templates/AGENTS.md) | Android 프로젝트용 `AGENTS.md`, `CLAUDE.md`(`@AGENTS.md` 한 줄) |

## 설치

```bash
git clone https://github.com/dltmddyd321/seungyong-ai-kit.git ~/seungyong-ai-kit
cd ~/seungyong-ai-kit
./install.sh --dry-run   # 바뀔 내용 확인
./install.sh             # 범용 skills/commands 링크 + rules import
./install.sh --with-android   # Android 전용 항목까지 함께 설치
```

옵션(`--with-writing`, `--with-android`, `--codex`, `--no-rules`, `--uninstall`), 이름 충돌, 설치 후 채워야 할 값, Codex 사용법 같은 주의사항은 [docs/SETUP.md](docs/SETUP.md)에 정리했습니다. 처음 설치할 때 한 번 읽어 주세요.

## License

[MIT](LICENSE)
