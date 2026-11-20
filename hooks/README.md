# hooks

## check-claude-agents-sync.sh

`CLAUDE.md`를 Edit/Write한 직후(PostToolUse) 실행된다. 같은 저장소의 `AGENTS.md`와 내용이 다르면, 에이전트에게 "AGENTS.md도 맞춰 고쳐라"는 컨텍스트와 diff를 돌려준다.

- `CLAUDE.md`에 `@AGENTS.md` 한 줄로 불러오는 방식(`rules/agent-config.md` 1번, 권장)을 쓰고 있으면 아무것도 하지 않는다.
- 두 파일을 각각 따로 유지하는(미러링) 저장소에서만 의미가 있다.
- `jq`가 필요하다.

## 설치

1. 스크립트를 프로젝트의 `.claude/hooks/`에 복사한다.
2. `settings.example.json`의 `hooks` 블록을 프로젝트의 `.claude/settings.json`(공유) 또는 `.claude/settings.local.json`(개인)에 합친다.

```bash
mkdir -p .claude/hooks
cp hooks/check-claude-agents-sync.sh .claude/hooks/
```
