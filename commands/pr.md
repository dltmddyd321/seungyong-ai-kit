---
description: 현재 브랜치의 작업을 바탕으로 GitHub PR을 만든다. /issue로 시작한 작업의 마무리 단계. 사용법: /pr
---

`{BASE_BRANCH}`는 프로젝트의 통합 브랜치(예: `dev`, `main`)로 바꿔서 설치한다.

## 수행 순서

**1. 컨텍스트 수집**

아래를 병렬로 수집한다.
```bash
git branch --show-current                              # 현재 브랜치
git diff {BASE_BRANCH}...HEAD --stat                   # 변경 파일 목록
git log {BASE_BRANCH}...HEAD --pretty=format:"%s"      # 커밋 메시지 목록
```

`.claude/current_issue.md`가 있으면 읽어서 `title`, `url`을 가져온다.
없으면 브랜치명을 제목으로 쓴다.

**2. PR 제목/본문 작성**

PR 제목: `{이슈 제목}` (current_issue.md의 title)

PR 본문:
```
## 개요
{이슈 URL} 에서 확인
{변경 내용 1~3줄 요약}

## 변경 파일
{git diff --stat 결과를 파일별로 정리}

## 테스트
- [ ] 빌드 확인
- [ ] {변경 내용에 맞는 구체적인 테스트 항목 1~3개}
```

**3. PR 생성**

```bash
gh pr create \
  --base {BASE_BRANCH} \
  --title "{PR 제목}" \
  --body "{PR 본문}"
```

**4. 완료**
- 생성된 PR URL을 출력한다.
- `open {PR URL}`로 브라우저에서 바로 연다.
