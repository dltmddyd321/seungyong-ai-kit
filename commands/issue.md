---
description: 이슈 트래커 URL과 제목으로 작업 브랜치를 만들고 커밋 메시지 첫 줄을 고정한다. 사용법: /issue <이슈 URL> <제목>
---

입력($ARGUMENTS) 형식: `{이슈 URL} {제목}`
예시: `https://issues.example.com/browse/PROJ-123 설정 화면 상단 배지 제거`

## 수행 순서

**1. 파싱**
- 첫 번째 토큰 = 이슈 URL, 나머지 전체 = 이슈 제목
- URL에서 이슈 키를 추출한다. Jira 형식이면 `[A-Z][A-Z0-9]+-\d+` 패턴(예: `PROJ-123`), GitHub/GitLab 이슈면 `issue-<번호>`처럼 저장소 관례에 맞춘다.

**2. 브랜치 생성**

별도 worktree를 만들지 않고 현재 워크트리에서 브랜치를 만든다. 미커밋 변경이 있으면 진행 전에 stash할지 커밋할지 사용자에게 묻는다.

```bash
git branch --show-current   # 현재 브랜치 확인 (출력용)
git checkout -b {이슈 키}    # 브랜치 생성
# 이미 있으면: git checkout {이슈 키}
```

**3. .claude/current_issue.md 저장**

아래 형식으로 Write한다.
```
id: {이슈 키}
title: {이슈 제목}
url: {이슈 URL}
commit_prefix: {이슈 URL} {이슈 제목}
```

프로젝트 `AGENTS.md`의 "이슈 커밋 규칙"이 이 파일의 `commit_prefix`를 커밋 메시지 첫 줄로 고정한다. 새 이슈로 바꿀 때 `/issue`를 다시 실행하면 덮어쓴다.

**4. 완료 메시지 출력**
- 생성한 브랜치명
- 앞으로 모든 커밋에 쓸 첫 줄: `{이슈 URL} {이슈 제목}`
